import Flutter
import UIKit
import AVFoundation
import Photos

public class NativeVideoEditorPlugin: NSObject, FlutterPlugin {
    private var currentExportSession: AVAssetExportSession?
    private var progressEventSink: FlutterEventSink?
    private var progressTimer: Timer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_video_editor", binaryMessenger: registrar.messenger())
        let instance = NativeVideoEditorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let progressChannel = FlutterEventChannel(name: "native_video_editor/progress", binaryMessenger: registrar.messenger())
        progressChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "trimVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let startTimeMs = args["startTimeMs"] as? Int,
                  let endTimeMs = args["endTimeMs"] as? Int else {
                result(flutterError("INVALID_ARGS", message: "Invalid arguments"))
                return
            }

            trimVideo(inputPath: inputPath, outputPath: outputPath,
                      startTimeMs: startTimeMs, endTimeMs: endTimeMs, result: result)

        case "rotateVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let degrees = args["degrees"] as? Int else {
                result(flutterError("INVALID_ARGS", message: "Invalid arguments"))
                return
            }

            rotateVideo(inputPath: inputPath, outputPath: outputPath,
                        degrees: degrees, result: result)

        case "cropVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let x = args["x"] as? Int,
                  let y = args["y"] as? Int,
                  let width = args["width"] as? Int,
                  let height = args["height"] as? Int else {
                result(flutterError("INVALID_ARGS", message: "Invalid arguments"))
                return
            }

            cropVideo(inputPath: inputPath, outputPath: outputPath,
                      x: x, y: y, width: width, height: height, result: result)

        case "processVideo":
            handleProcessVideo(call: call, result: result)

        case "getVideoInfo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String else {
            result(flutterError("INVALID_ARGS", message: "Invalid arguments"))
            return
        }

        getVideoInfo(videoPath: videoPath, result: result)

        case "cancelProcessing":
            currentExportSession?.cancelExport()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func trimVideo(inputPath: String, outputPath: String,
                          startTimeMs: Int, endTimeMs: Int, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))

        let startTime = CMTime(value: CMTimeValue(startTimeMs), timescale: 1000)
        let endTime = CMTime(value: CMTimeValue(endTimeMs), timescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        // Check if video has metadata rotation
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let preferredTransform = videoTrack.preferredTransform
            // Check if the transform is not identity (has rotation/orientation)
            if !preferredTransform.isIdentity {

                // Create composition to apply the preferred transform
                let composition = AVMutableComposition()
                guard let compositionVideoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    result(flutterError("COMPOSITION_ERROR", message: "Failed to create composition track"))
                    return
                }

                var compositionAudioTrack: AVMutableCompositionTrack?
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    compositionAudioTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid)
                }

                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

                    if let audioTrack = asset.tracks(withMediaType: .audio).first,
                       let compAudioTrack = compositionAudioTrack {
                        try compAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                    }
                } catch {
                    result(flutterError("INSERT_ERROR", message: "Failed to insert track", error: error))
                    return
                }

                // Create video composition with the preferred transform
                let videoComp = AVMutableVideoComposition()
                videoComp.frameDuration = frameDuration(for: videoTrack)

                let naturalSize = videoTrack.naturalSize
                let naturalBounds = CGRect(origin: .zero, size: naturalSize)
                let preferredBounds = naturalBounds.applying(preferredTransform)
                let orientationAdjustment = CGAffineTransform(
                    translationX: -preferredBounds.minX,
                    y: -preferredBounds.minY
                )

                let orientationTransform = preferredTransform.concatenating(orientationAdjustment)
                let renderSize = CGSize(width: abs(preferredBounds.width), height: abs(preferredBounds.height))

                videoComp.renderSize = renderSize

                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                layerInstruction.setTransform(orientationTransform, at: .zero)

                instruction.layerInstructions = [layerInstruction]
                videoComp.instructions = [instruction]

                // Use composition for export
                let presetName = AVAssetExportPresetHighestQuality
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: presetName) else {
                    result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
                    return
                }

                currentExportSession = exportSession
                exportSession.videoComposition = videoComp
                exportSession.outputURL = URL(fileURLWithPath: outputPath)
                exportSession.outputFileType = .mp4
                exportSession.shouldOptimizeForNetworkUse = true

                startProgressReporting()
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        self.stopProgressReporting()
                        switch exportSession.status {
                        case .completed:
                            result([
                                "outputPath": outputPath,
                                "isReEncoded": true
                            ])
                        case .failed:
                            result(self.flutterError("TRIM_ERROR", message: "Failed to trim video", error: exportSession.error))
                        case .cancelled:
                            result(self.flutterError("CANCELLED", message: "Export cancelled"))
                        default:
                            result(self.flutterError("UNKNOWN", message: "Unknown export status", error: exportSession.error))
                        }
                        self.currentExportSession = nil
                    }
                }
                return
            }
        }

        // Use passthrough if no rotation needed
        guard let exportSession = AVAssetExportSession(asset: asset,
                                                       presetName: AVAssetExportPresetPassthrough) else {
            result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
            return
        }

        currentExportSession = exportSession

        exportSession.timeRange = timeRange
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        startProgressReporting()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.stopProgressReporting()
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": false
                    ])
                case .failed:
                    result(self.flutterError("TRIM_ERROR", message: "Failed to trim video", error: exportSession.error))
                case .cancelled:
                    result(self.flutterError("CANCELLED", message: "Export cancelled"))
                default:
                    result(self.flutterError("UNKNOWN", message: "Unknown export status", error: exportSession.error))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func rotateVideo(inputPath: String, outputPath: String,
                            degrees: Int, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            result(flutterError("NO_VIDEO", message: "No video track found"))
            return
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(flutterError("COMPOSITION_ERROR", message: "Failed to create composition track"))
            return
        }

        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        }

        do {
            try compositionVideoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: videoTrack,
                at: .zero)

            if let audioTrack = asset.tracks(withMediaType: .audio).first,
               let compAudioTrack = compositionAudioTrack {
                try compAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: audioTrack,
                    at: .zero)
            }
        } catch {
            result(flutterError("INSERT_ERROR", message: "Failed to insert track", error: error))
            return
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = frameDuration(for: videoTrack)

        let naturalSize = videoTrack.naturalSize
        let preferredTransform = videoTrack.preferredTransform

        // Apply orientation adjustment to handle existing metadata rotation properly
        let naturalBounds = CGRect(origin: .zero, size: naturalSize)
        let preferredBounds = naturalBounds.applying(preferredTransform)
        let orientationAdjustment = CGAffineTransform(
            translationX: -preferredBounds.minX,
            y: -preferredBounds.minY
        )
        let orientationTransform = preferredTransform.concatenating(orientationAdjustment)

        // Calculate oriented size for render calculations
        var orientedSize = CGSize(width: abs(preferredBounds.width), height: abs(preferredBounds.height))

        var transform = orientationTransform

        // iOS CGAffineTransform rotates counter-clockwise for positive angles
        // To match Android behavior (positive = clockwise), we negate the radians
        let radians = CGFloat(degrees) * .pi / 180
        let clockwiseRadians = -radians

        // Rotate around the center of the oriented video
        let centerX = orientedSize.width / 2
        let centerY = orientedSize.height / 2

        transform = transform.translatedBy(x: centerX, y: centerY)
        transform = transform.rotated(by: clockwiseRadians)
        transform = transform.translatedBy(x: -centerX, y: -centerY)

        // Calculate renderSize from actual transformed bounds (more accurate for metadata-rotated videos)
        // Use naturalSize here because transform expects input in natural/file coordinate space
        let testRect = CGRect(origin: .zero, size: naturalSize)
        let transformedBounds = testRect.applying(transform)

        // Get the actual dimensions after the full transform chain
        let finalWidth = abs(transformedBounds.width)
        let finalHeight = abs(transformedBounds.height)
        let renderSize = CGSize(width: finalWidth, height: finalHeight)

        // Center the video in the renderSize
        let targetMinX: CGFloat = (renderSize.width - transformedBounds.width) / 2
        let additionalTranslateX = targetMinX - transformedBounds.minX

        let targetMinY: CGFloat = (renderSize.height - transformedBounds.height) / 2
        let additionalTranslateY = targetMinY - transformedBounds.minY

        transform = transform.concatenating(CGAffineTransform(translationX: additionalTranslateX, y: additionalTranslateY))

        videoComposition.renderSize = renderSize

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality) else {
            result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
            return
        }

        currentExportSession = exportSession

        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        startProgressReporting()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.stopProgressReporting()
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": true
                    ])
                case .failed:
                    result(self.flutterError("ROTATE_ERROR", message: "Failed to rotate video", error: exportSession.error))
                case .cancelled:
                    result(self.flutterError("CANCELLED", message: "Export cancelled"))
                default:
                    result(self.flutterError("UNKNOWN", message: "Unknown export status", error: exportSession.error))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func cropVideo(inputPath: String, outputPath: String,
                          x: Int, y: Int, width: Int, height: Int, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            result(flutterError("NO_VIDEO", message: "No video track found"))
            return
        }

        let preferredTransform = videoTrack.preferredTransform
        let naturalSize = videoTrack.naturalSize

        let cropRectDisplay = CGRect(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: CGFloat(height)
        )

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(flutterError("COMPOSITION_ERROR", message: "Failed to create composition track"))
            return
        }

        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        }

        do {
            try compositionVideoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: videoTrack,
                at: .zero)

            if let audioTrack = asset.tracks(withMediaType: .audio).first,
               let compAudioTrack = compositionAudioTrack {
                try compAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: audioTrack,
                    at: .zero)
            }
        } catch {
            result(flutterError("INSERT_ERROR", message: "Failed to insert track", error: error))
            return
        }

        // Create video composition for cropping
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = frameDuration(for: videoTrack)

        // Create layer instruction with crop transform
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)

        let naturalBounds = CGRect(origin: .zero, size: naturalSize)
        let preferredBounds = naturalBounds.applying(preferredTransform)
        let orientationAdjustment = CGAffineTransform(
            translationX: -preferredBounds.minX,
            y: -preferredBounds.minY
        )

        let orientationTransform = preferredTransform.concatenating(orientationAdjustment)

        guard orientationTransform.isNearlyInvertible else {
            result(flutterError("CROP_ERROR", message: "Invalid orientation transform"))
            return
        }
        let orientationInverse = orientationTransform.inverted()

        let displayCorners = [
            cropRectDisplay.origin,
            CGPoint(x: cropRectDisplay.maxX, y: cropRectDisplay.minY),
            CGPoint(x: cropRectDisplay.minX, y: cropRectDisplay.maxY),
            CGPoint(x: cropRectDisplay.maxX, y: cropRectDisplay.maxY)
        ]

        let fileCorners = displayCorners.map { $0.applying(orientationInverse) }

        let fileMinX = fileCorners.map { $0.x }.min() ?? 0
        let fileMinY = fileCorners.map { $0.y }.min() ?? 0
        let fileMaxX = fileCorners.map { $0.x }.max() ?? 0
        let fileMaxY = fileCorners.map { $0.y }.max() ?? 0

        let fileCropRect = CGRect(
            x: fileMinX,
            y: fileMinY,
            width: fileMaxX - fileMinX,
            height: fileMaxY - fileMinY
        )

        let cropTranslation = CGAffineTransform(
            translationX: -fileCropRect.origin.x,
            y: -fileCropRect.origin.y
        )

        var transform = cropTranslation.concatenating(orientationTransform)

        let transformedCorners = fileCorners.map { $0.applying(transform) }

        let minX = transformedCorners.map { $0.x }.min() ?? 0
        let minY = transformedCorners.map { $0.y }.min() ?? 0
        let maxX = transformedCorners.map { $0.x }.max() ?? 0
        let maxY = transformedCorners.map { $0.y }.max() ?? 0

        let correctionTransform = CGAffineTransform(
            translationX: -minX,
            y: -minY
        )
        transform = transform.concatenating(correctionTransform)

        let outputWidth = max((maxX - minX).rounded(), CGFloat(1))
        let outputHeight = max((maxY - minY).rounded(), CGFloat(1))
        let renderSize = CGSize(width: outputWidth, height: outputHeight)

        layerInstruction.setTransform(transform, at: .zero)
        videoComposition.renderSize = renderSize

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality) else {
            result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
            return
        }

        currentExportSession = exportSession

        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        startProgressReporting()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.stopProgressReporting()
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": true
                    ])
                case .failed:
                    result(self.flutterError("CROP_ERROR", message: "Failed to crop video", error: exportSession.error))
                case .cancelled:
                    result(self.flutterError("CANCELLED", message: "Export cancelled"))
                default:
                    result(self.flutterError("UNKNOWN", message: "Unknown export status", error: exportSession.error))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func handleProcessVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String else {
            result(flutterError("INVALID_ARGS", message: "Invalid arguments"))
            return
        }

        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
        var composition = AVMutableComposition()
        var videoComposition: AVMutableVideoComposition?

        // Handle trim
        var timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        if let trimStartMs = args["trimStartMs"] as? Int,
           let trimEndMs = args["trimEndMs"] as? Int {
            let startTime = CMTime(value: CMTimeValue(trimStartMs), timescale: 1000)
            let endTime = CMTime(value: CMTimeValue(trimEndMs), timescale: 1000)
            timeRange = CMTimeRange(start: startTime, end: endTime)
        }

        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(flutterError("COMPOSITION_ERROR", message: "Failed to create composition"))
            return
        }

        do {
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

            if let audioTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
        } catch {
            result(flutterError("INSERT_ERROR", message: "Failed to insert track", error: error))
            return
        }

        var isReEncoded = false

        let naturalSize = videoTrack.naturalSize
        let preferredTransform = videoTrack.preferredTransform
        var finalTransform = preferredTransform
        var renderSize = naturalSize

        // Check if video has metadata rotation even if no explicit transformations requested
        let hasMetadataRotation = !preferredTransform.isIdentity

        if let cropX = args["cropX"] as? Int,
           let cropY = args["cropY"] as? Int,
           let cropWidth = args["cropWidth"] as? Int,
           let cropHeight = args["cropHeight"] as? Int {
            isReEncoded = true

            let requestedRotation = args["rotateDegrees"] as? Int ?? 0
            let normalizedRotation = ((requestedRotation % 360) + 360) % 360

            let naturalBounds = CGRect(origin: .zero, size: naturalSize)
            let preferredBounds = naturalBounds.applying(preferredTransform)
            let orientationAdjustment = CGAffineTransform(
                translationX: -preferredBounds.minX,
                y: -preferredBounds.minY
            )

            let orientationTransform = preferredTransform.concatenating(orientationAdjustment)

            guard orientationTransform.isNearlyInvertible else {
                result(flutterError("PROCESS_ERROR", message: "Invalid orientation transform during crop"))
                return
            }
            let orientationInverse = orientationTransform.inverted()

            let cropRectDisplay = CGRect(
                x: CGFloat(cropX),
                y: CGFloat(cropY),
                width: CGFloat(cropWidth),
                height: CGFloat(cropHeight)
            )

            let displayCorners = [
                cropRectDisplay.origin,
                CGPoint(x: cropRectDisplay.maxX, y: cropRectDisplay.minY),
                CGPoint(x: cropRectDisplay.minX, y: cropRectDisplay.maxY),
                CGPoint(x: cropRectDisplay.maxX, y: cropRectDisplay.maxY)
            ]

            let fileCorners = displayCorners.map { $0.applying(orientationInverse) }

            let fileMinX = fileCorners.map { $0.x }.min() ?? 0
            let fileMinY = fileCorners.map { $0.y }.min() ?? 0
            let fileMaxX = fileCorners.map { $0.x }.max() ?? 0
            let fileMaxY = fileCorners.map { $0.y }.max() ?? 0

            let fileCropRect = CGRect(
                x: fileMinX,
                y: fileMinY,
                width: fileMaxX - fileMinX,
                height: fileMaxY - fileMinY
            )

            let cropTranslation = CGAffineTransform(
                translationX: -fileCropRect.origin.x,
                y: -fileCropRect.origin.y
            )

            var transform = cropTranslation.concatenating(orientationTransform)

            if normalizedRotation != 0 {
                // iOS CGAffineTransform rotates counter-clockwise for positive angles.
                // To match Android behavior (positive = clockwise), negate the radians.
                let radians = CGFloat(normalizedRotation) * .pi / 180
                let clockwiseRadians = -radians
                let rotationTransform = CGAffineTransform(rotationAngle: clockwiseRadians)
                transform = transform.concatenating(rotationTransform)
            }

            let transformedCorners = fileCorners.map { $0.applying(transform) }

            let minX = transformedCorners.map { $0.x }.min() ?? 0
            let minY = transformedCorners.map { $0.y }.min() ?? 0
            let maxX = transformedCorners.map { $0.x }.max() ?? 0
            let maxY = transformedCorners.map { $0.y }.max() ?? 0

            let correctionTransform = CGAffineTransform(
                translationX: -minX,
                y: -minY
            )
            transform = transform.concatenating(correctionTransform)

            let outputWidth = max((maxX - minX).rounded(), CGFloat(1))
            let outputHeight = max((maxY - minY).rounded(), CGFloat(1))
            renderSize = CGSize(width: outputWidth, height: outputHeight)

            finalTransform = transform

        } else if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
            isReEncoded = true

            // Apply orientation adjustment to handle existing metadata rotation properly
            let naturalBounds = CGRect(origin: .zero, size: naturalSize)
            let preferredBounds = naturalBounds.applying(preferredTransform)
            let orientationAdjustment = CGAffineTransform(
                translationX: -preferredBounds.minX,
                y: -preferredBounds.minY
            )
            let orientationTransform = preferredTransform.concatenating(orientationAdjustment)

            // Calculate oriented size for render calculations
            var orientedSize = CGSize(width: abs(preferredBounds.width), height: abs(preferredBounds.height))

            var transform = orientationTransform

            // iOS CGAffineTransform rotates counter-clockwise for positive angles
            // To match Android behavior (positive = clockwise), we negate the radians
            let radians = CGFloat(rotateDegrees) * .pi / 180
            let clockwiseRadians = -radians

            // Rotate around the center of the input video
            let centerX = orientedSize.width / 2
            let centerY = orientedSize.height / 2

            transform = transform.translatedBy(x: centerX, y: centerY)
            transform = transform.rotated(by: clockwiseRadians)
            transform = transform.translatedBy(x: -centerX, y: -centerY)

            // Calculate renderSize from actual transformed bounds (more accurate for metadata-rotated videos)
            // Use naturalSize here because transform expects input in natural/file coordinate space
            let testRect = CGRect(origin: .zero, size: naturalSize)
            let transformedBounds = testRect.applying(transform)

            // Get the actual dimensions after the full transform chain
            let finalWidth = abs(transformedBounds.width)
            let finalHeight = abs(transformedBounds.height)
            renderSize = CGSize(width: finalWidth, height: finalHeight)

            // Center the video in the renderSize
            let targetMinX: CGFloat = (renderSize.width - transformedBounds.width) / 2
            let additionalTranslateX = targetMinX - transformedBounds.minX

            let targetMinY: CGFloat = (renderSize.height - transformedBounds.height) / 2
            let additionalTranslateY = targetMinY - transformedBounds.minY

            transform = transform.concatenating(CGAffineTransform(translationX: additionalTranslateX, y: additionalTranslateY))

            finalTransform = transform
        } else if hasMetadataRotation {
            // If no explicit transformations but video has metadata rotation, apply it
            isReEncoded = true

            let naturalBounds = CGRect(origin: .zero, size: naturalSize)
            let preferredBounds = naturalBounds.applying(preferredTransform)
            let orientationAdjustment = CGAffineTransform(
                translationX: -preferredBounds.minX,
                y: -preferredBounds.minY
            )

            let orientationTransform = preferredTransform.concatenating(orientationAdjustment)
            renderSize = CGSize(width: abs(preferredBounds.width), height: abs(preferredBounds.height))
            finalTransform = orientationTransform
        }

        if isReEncoded {
            videoComposition = AVMutableVideoComposition()
            videoComposition!.frameDuration = frameDuration(for: videoTrack)
            videoComposition!.renderSize = renderSize

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(finalTransform, at: .zero)

            instruction.layerInstructions = [layerInstruction]
            videoComposition!.instructions = [instruction]
        }

        // Export
        let presetName = isReEncoded ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: presetName) else {
            result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
            return
        }

        currentExportSession = exportSession

        if let videoComp = videoComposition {
            exportSession.videoComposition = videoComp
        }

        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        if !isReEncoded {
            exportSession.timeRange =  CMTimeRange(start: .zero, duration: composition.duration)
        }

        startProgressReporting()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.stopProgressReporting()
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": isReEncoded
                    ])
                case .failed:
                    result(self.flutterError("PROCESS_ERROR", message: "Failed to process video", error: exportSession.error))
                case .cancelled:
                    result(self.flutterError("CANCELLED", message: "Export cancelled"))
                default:
                    result(self.flutterError("UNKNOWN", message: "Unknown export status", error: exportSession.error))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func frameDuration(for track: AVAssetTrack) -> CMTime {
        let nominal = track.nominalFrameRate
        if nominal.isFinite && nominal > 0 {
            return CMTime(value: 1, timescale: Int32(round(nominal)))
        }
        if track.minFrameDuration.isValid && track.minFrameDuration.value != 0 {
            return track.minFrameDuration
        }
        return CMTime(value: 1, timescale: 30)
    }

    private func flutterError(_ code: String, message: String, error: Error? = nil, details: Any? = nil) -> FlutterError {
        let resolvedMessage = error?.localizedDescription ?? message
        let resolvedDetails: Any?
        if let details = details {
            resolvedDetails = details
        } else if let error = error {
            resolvedDetails = String(describing: error)
        } else {
            resolvedDetails = nil
        }
        return FlutterError(code: code, message: resolvedMessage, details: resolvedDetails)
    }

    private func getVideoInfo(videoPath: String, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))

        // Use the synchronous properties for iOS compatibility
        let duration = asset.duration
        let tracks = asset.tracks

        var info: [String: Any] = [
            "duration": CMTimeGetSeconds(duration) * 1000, // Convert to milliseconds
        ]

        if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
            let naturalSize = videoTrack.naturalSize
            let preferredTransform = videoTrack.preferredTransform
            let nominalFrameRate = videoTrack.nominalFrameRate

            info["width"] = Int(naturalSize.width)
            info["height"] = Int(naturalSize.height)
            info["frameRate"] = nominalFrameRate

            let angle = atan2(preferredTransform.b, preferredTransform.a)
            let rotation = Int(angle * 180 / .pi)
            info["rotation"] = rotation
        }

        if let audioTrack = tracks.first(where: { $0.mediaType == .audio }) {
            info["hasAudio"] = true
        }

        result(info)
    }

    private func startProgressReporting() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let session = self.currentExportSession,
                  let sink = self.progressEventSink else { return }

            let progress = Double(session.progress)
            sink(progress)
        }
    }

    private func stopProgressReporting() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

private extension CGAffineTransform {
    var isNearlyInvertible: Bool {
        let determinant = (a * d) - (b * c)
        return abs(determinant) > 1e-8
    }
}

extension NativeVideoEditorPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        progressEventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        progressEventSink = nil
        stopProgressReporting()
        return nil
    }
}
