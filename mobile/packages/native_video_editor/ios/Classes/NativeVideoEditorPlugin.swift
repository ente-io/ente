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

        guard let exportSession = AVAssetExportSession(asset: asset,
                                                       presetName: AVAssetExportPresetPassthrough) else {
            result(flutterError("EXPORT_ERROR", message: "Failed to create export session"))
            return
        }

        currentExportSession = exportSession

        let startTime = CMTime(value: CMTimeValue(startTimeMs), timescale: 1000)
        let endTime = CMTime(value: CMTimeValue(endTimeMs), timescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

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
        var renderSize = naturalSize
        var transform = CGAffineTransform.identity

        switch degrees {
        case 90:
            transform = CGAffineTransform(rotationAngle: .pi / 2)
                .translatedBy(x: 0, y: -naturalSize.width)
            renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        case 180:
            transform = CGAffineTransform(rotationAngle: .pi)
                .translatedBy(x: -naturalSize.width, y: -naturalSize.height)
        case 270:
            transform = CGAffineTransform(rotationAngle: -.pi / 2)
                .translatedBy(x: -naturalSize.height, y: 0)
            renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        default:
            result(flutterError("INVALID_DEGREES", message: "Degrees must be 90, 180, or 270"))
            return
        }

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

        // Keep rotation handling simple - preferredTransform works fine!
        // But adjust crop coordinates from display space to file space
        let preferredTransform = videoTrack.preferredTransform
        let naturalSize = videoTrack.naturalSize

        // Detect if video has 90° or 270° rotation metadata
        let b = preferredTransform.b
        let c = preferredTransform.c
        let has90Or270Rotation = (b == 1.0 && c == -1.0) || (b == -1.0 && c == 1.0)

        // Flutter sends coordinates in DISPLAY space (after rotation)
        // But we need FILE space coordinates (before rotation)
        // For 90°/270° videos, dimensions are swapped
        var cropX = x
        var cropY = y
        var cropWidth = width
        var cropHeight = height

        if has90Or270Rotation {
            // Video file dimensions are swapped compared to display
            // Just swap width/height for the output
            // Keep x, y the same - coordinates work in display space
            cropWidth = height  // Output dimensions swap
            cropHeight = width
        }

        // Collect debug info to return to Flutter
        var debugInfo: [String: Any] = [
            "videoNaturalSize": "\(Int(naturalSize.width))x\(Int(naturalSize.height))",
            "has90Or270Rotation": has90Or270Rotation,
            "preferredTransform": [
                "a": preferredTransform.a,
                "b": preferredTransform.b,
                "c": preferredTransform.c,
                "d": preferredTransform.d,
                "tx": preferredTransform.tx,
                "ty": preferredTransform.ty
            ],
            "inputCrop": ["x": x, "y": y, "w": width, "h": height],
            "adjustedCrop": ["x": cropX, "y": cropY, "w": cropWidth, "h": cropHeight]
        ]

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
        videoComposition.renderSize = CGSize(width: cropWidth, height: cropHeight)

        // Create layer instruction with crop transform
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)

        // Simple approach: crop translation THEN rotation
        // This replaces the deprecated setCropRectangle
        let cropTransform = CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY))
        let finalTransform = cropTransform.concatenating(preferredTransform)

        // Add final transform to debug info
        debugInfo["finalTransform"] = [
            "a": finalTransform.a,
            "b": finalTransform.b,
            "c": finalTransform.c,
            "d": finalTransform.d,
            "tx": finalTransform.tx,
            "ty": finalTransform.ty
        ]
        debugInfo["renderSize"] = "\(cropWidth)x\(cropHeight)"

        layerInstruction.setTransform(finalTransform, at: .zero)

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
                        "isReEncoded": true,
                        "debugInfo": debugInfo
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
        var debugInfo: [String: Any] = [:]
        var cropBlockEntered = false
        var debugInfoCountAfterPopulate = 0

        if let cropX = args["cropX"] as? Int,
           let cropY = args["cropY"] as? Int,
           let cropWidth = args["cropWidth"] as? Int,
           let cropHeight = args["cropHeight"] as? Int {
            cropBlockEntered = true
            isReEncoded = true

            // Collect debug info
            debugInfo["operation"] = "processVideo"
            debugInfo["videoNaturalSize"] = "\(Int(naturalSize.width))x\(Int(naturalSize.height))"
            debugInfo["preferredTransform"] = [
                "a": preferredTransform.a,
                "b": preferredTransform.b,
                "c": preferredTransform.c,
                "d": preferredTransform.d,
                "tx": preferredTransform.tx,
                "ty": preferredTransform.ty
            ]
            debugInfo["inputCrop"] = ["x": cropX, "y": cropY, "w": cropWidth, "h": cropHeight]
            debugInfoCountAfterPopulate = debugInfo.count

            let cropWidthF = CGFloat(cropWidth)
            let cropHeightF = CGFloat(cropHeight)

            // Normalize rotation degrees to [0, 360)
            let requestedRotation = args["rotateDegrees"] as? Int ?? 0
            let normalizedRotation = ((requestedRotation % 360) + 360) % 360

            let naturalBounds = CGRect(origin: .zero, size: naturalSize)
            let preferredBounds = naturalBounds.applying(preferredTransform)
            let orientationAdjustment = CGAffineTransform(
                translationX: -preferredBounds.minX,
                y: -preferredBounds.minY
            )

            if orientationAdjustment.tx != 0 || orientationAdjustment.ty != 0 {
                debugInfo["orientationAdjustment"] = [
                    "x": orientationAdjustment.tx,
                    "y": orientationAdjustment.ty
                ]
            }

            var transform = preferredTransform.concatenating(orientationAdjustment)

            let cropTranslation = CGAffineTransform(
                translationX: -CGFloat(cropX),
                y: -CGFloat(cropY)
            )
            transform = transform.concatenating(cropTranslation)

            debugInfo["cropTranslationPreRotation"] = [
                "x": cropTranslation.tx,
                "y": cropTranslation.ty
            ]

            if normalizedRotation != 0 {
                // iOS CGAffineTransform rotates counter-clockwise for positive angles.
                // To match Android behavior (positive = clockwise), negate the radians.
                let radians = CGFloat(normalizedRotation) * .pi / 180
                let clockwiseRadians = -radians
                let rotationTransform = CGAffineTransform(rotationAngle: clockwiseRadians)
                transform = transform.concatenating(rotationTransform)
                debugInfo["rotationDegrees"] = normalizedRotation
            } else if requestedRotation != 0 {
                // Preserve debug info if non-multiple of 360 was requested
                debugInfo["rotationDegrees"] = requestedRotation
            }

            // Project the crop rectangle through the current transform to work out bounds
            let cropRect = CGRect(
                x: CGFloat(cropX),
                y: CGFloat(cropY),
                width: cropWidthF,
                height: cropHeightF
            )

            let cropCorners = [
                cropRect.origin,
                CGPoint(x: cropRect.maxX, y: cropRect.minY),
                CGPoint(x: cropRect.minX, y: cropRect.maxY),
                CGPoint(x: cropRect.maxX, y: cropRect.maxY)
            ]

            let transformedCorners = cropCorners.map { $0.applying(transform) }

            let minX = transformedCorners.map { $0.x }.min() ?? 0
            let minY = transformedCorners.map { $0.y }.min() ?? 0
            let maxX = transformedCorners.map { $0.x }.max() ?? 0
            let maxY = transformedCorners.map { $0.y }.max() ?? 0

            debugInfo["postRotationBounds"] = [
                "minX": Double(minX),
                "minY": Double(minY),
                "maxX": Double(maxX),
                "maxY": Double(maxY)
            ]

            let correctionTransform = CGAffineTransform(
                translationX: -minX,
                y: -minY
            )
            transform = transform.concatenating(correctionTransform)

            if correctionTransform.tx != 0 || correctionTransform.ty != 0 {
                debugInfo["rotationCorrectionTranslation"] = [
                    "x": correctionTransform.tx,
                    "y": correctionTransform.ty
                ]
            }

            let outputWidth = maxX - minX
            let outputHeight = maxY - minY
            renderSize = CGSize(width: outputWidth, height: outputHeight)

            debugInfo["computedRenderSize"] = [
                "width": Double(renderSize.width),
                "height": Double(renderSize.height)
            ]

            finalTransform = transform

            debugInfo["finalTransformBeforeComposition"] = [
                "a": transform.a,
                "b": transform.b,
                "c": transform.c,
                "d": transform.d,
                "tx": transform.tx,
                "ty": transform.ty
            ]

            debugInfo["renderSize"] = "\(Int(renderSize.width))x\(Int(renderSize.height))"

        } else if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
            isReEncoded = true

            var orientedSize = naturalSize.applying(preferredTransform)
            orientedSize = CGSize(width: abs(orientedSize.width), height: abs(orientedSize.height))

            var transform = preferredTransform

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

            // Set renderSize based on rotation
            if abs(rotateDegrees) == 90 || abs(rotateDegrees) == 270 {
                renderSize = CGSize(width: orientedSize.height, height: orientedSize.width)
            } else {
                renderSize = orientedSize
            }

            // Use bounds testing to calculate the necessary translation to center the video
            let testRect = CGRect(origin: .zero, size: orientedSize)
            let finalBounds = testRect.applying(transform)

            // Center the video in the renderSize
            let targetMinX: CGFloat = (renderSize.width - finalBounds.width) / 2
            let additionalTranslateX = targetMinX - finalBounds.minX

            let targetMinY: CGFloat = (renderSize.height - finalBounds.height) / 2
            let additionalTranslateY = targetMinY - finalBounds.minY

            transform = transform.concatenating(CGAffineTransform(translationX: additionalTranslateX, y: additionalTranslateY))

            finalTransform = transform
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
            exportSession.timeRange = timeRange
        }

        // Add final renderSize to debugInfo
        var debugInfoCountBeforeExport = debugInfo.count
        if !debugInfo.isEmpty {
            debugInfo["renderSize"] = "\(Int(renderSize.width))x\(Int(renderSize.height))"
        }

        startProgressReporting()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.stopProgressReporting()
                switch exportSession.status {
                case .completed:
                    var resultDict: [String: Any] = [
                        "outputPath": outputPath,
                        "isReEncoded": isReEncoded,
                        // Diagnostic info to track debugInfo lifecycle
                        "_diagnostic_cropBlockEntered": cropBlockEntered,
                        "_diagnostic_debugInfoCountAfterPopulate": debugInfoCountAfterPopulate,
                        "_diagnostic_debugInfoCountBeforeExport": debugInfoCountBeforeExport,
                        "_diagnostic_debugInfoCountInCompletion": debugInfo.count
                    ]
                    if !debugInfo.isEmpty {
                        resultDict["debugInfo"] = debugInfo
                    }
                    result(resultDict)
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

    // Telegram's TGVideoOrientationForAsset - detect orientation from transform matrix
    // From TGPhotoEditorUtils.m:618-647
    private func videoOrientation(from transform: CGAffineTransform) -> UIImage.Orientation {
        let a = transform.a
        let b = transform.b
        let c = transform.c
        let d = transform.d

        // Telegram's exact detection logic
        if a == -1 && d == -1 {
            return .left  // 180° rotation
        } else if a == 1 && d == 1 {
            return .right  // 0° (no rotation)
        } else if b == -1 && c == 1 {
            return .down  // 270° CW
        } else {
            // Default case (b == 1, c == -1) or other variants
            return .up  // 90° CW
        }
    }

    // Telegram's TGVideoTransformForOrientation - builds complete transform
    // This replaces preferredTransform with explicit transform for each orientation
    private func buildTransformForOrientation(_ orientation: UIImage.Orientation,
                                             videoSize: CGSize,
                                             cropRect: CGRect) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        // Telegram's exact logic from TGPhotoEditorUtils.m:737-765
        switch orientation {
        case .up:  // 90° CW rotation
            // translate(size.height - crop.x, 0 - crop.y) + rotate(90°)
            transform = CGAffineTransform(translationX: videoSize.height - cropRect.origin.x,
                                         y: -cropRect.origin.y)
            transform = transform.rotated(by: .pi / 2)

        case .down:  // 270° CW rotation
            // translate(0 - crop.x, size.width - crop.y) + rotate(-90°)
            transform = CGAffineTransform(translationX: -cropRect.origin.x,
                                         y: videoSize.width - cropRect.origin.y)
            transform = transform.rotated(by: -.pi / 2)

        case .right:  // 0° (no rotation)
            // translate(0 - crop.x, 0 - crop.y) + rotate(0°)
            transform = CGAffineTransform(translationX: -cropRect.origin.x,
                                         y: -cropRect.origin.y)

        case .left:  // 180° rotation
            // translate(size.width - crop.x, size.height - crop.y) + rotate(180°)
            transform = CGAffineTransform(translationX: videoSize.width - cropRect.origin.x,
                                         y: videoSize.height - cropRect.origin.y)
            transform = transform.rotated(by: .pi)

        default:
            transform = CGAffineTransform(translationX: -cropRect.origin.x,
                                         y: -cropRect.origin.y)
        }

        return transform
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
