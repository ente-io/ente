import Flutter
import UIKit
import AVFoundation
import Photos

public class NativeVideoEditorPlugin: NSObject, FlutterPlugin {
    private var currentExportSession: AVAssetExportSession?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_video_editor", binaryMessenger: registrar.messenger())
        let instance = NativeVideoEditorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "trimVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let startTimeMs = args["startTimeMs"] as? Int,
                  let endTimeMs = args["endTimeMs"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            trimVideo(inputPath: inputPath, outputPath: outputPath,
                     startTimeMs: startTimeMs, endTimeMs: endTimeMs, result: result)

        case "rotateVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let degrees = args["degrees"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
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
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            cropVideo(inputPath: inputPath, outputPath: outputPath,
                     x: x, y: y, width: width, height: height, result: result)

        case "processVideo":
            handleProcessVideo(call: call, result: result)

        case "getVideoInfo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
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
            result(FlutterError(code: "EXPORT_ERROR", message: "Failed to create export session", details: nil))
            return
        }

        currentExportSession = exportSession

        // Set time range for trimming
        let startTime = CMTime(value: CMTimeValue(startTimeMs), timescale: 1000)
        let endTime = CMTime(value: CMTimeValue(endTimeMs), timescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        exportSession.timeRange = timeRange
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": false
                    ])
                case .failed:
                    result(FlutterError(code: "TRIM_ERROR",
                                      message: exportSession.error?.localizedDescription ?? "Unknown error",
                                      details: nil))
                case .cancelled:
                    result(FlutterError(code: "CANCELLED", message: "Export cancelled", details: nil))
                default:
                    result(FlutterError(code: "UNKNOWN", message: "Unknown export status", details: nil))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func rotateVideo(inputPath: String, outputPath: String,
                            degrees: Int, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            result(FlutterError(code: "NO_VIDEO", message: "No video track found", details: nil))
            return
        }

        // Create composition
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(FlutterError(code: "COMPOSITION_ERROR", message: "Failed to create composition track", details: nil))
            return
        }

        // Add audio track if present
        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        }

        // Insert tracks
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
            result(FlutterError(code: "INSERT_ERROR", message: error.localizedDescription, details: nil))
            return
        }

        // Create video composition with rotation
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let naturalSize = videoTrack.naturalSize
        var renderSize = naturalSize
        var transform = CGAffineTransform.identity

        // Calculate rotation transform
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
            result(FlutterError(code: "INVALID_DEGREES", message: "Degrees must be 90, 180, or 270", details: nil))
            return
        }

        videoComposition.renderSize = renderSize

        // Create layer instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // Export with PassThrough preset to avoid re-encoding when possible
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality) else {
            result(FlutterError(code: "EXPORT_ERROR", message: "Failed to create export session", details: nil))
            return
        }

        currentExportSession = exportSession

        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": true // Rotation with transform requires re-encoding
                    ])
                case .failed:
                    result(FlutterError(code: "ROTATE_ERROR",
                                      message: exportSession.error?.localizedDescription ?? "Unknown error",
                                      details: nil))
                case .cancelled:
                    result(FlutterError(code: "CANCELLED", message: "Export cancelled", details: nil))
                default:
                    result(FlutterError(code: "UNKNOWN", message: "Unknown export status", details: nil))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func cropVideo(inputPath: String, outputPath: String,
                          x: Int, y: Int, width: Int, height: Int, result: @escaping FlutterResult) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            result(FlutterError(code: "NO_VIDEO", message: "No video track found", details: nil))
            return
        }

        // Create composition
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(FlutterError(code: "COMPOSITION_ERROR", message: "Failed to create composition track", details: nil))
            return
        }

        // Add audio track if present
        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        }

        // Insert tracks
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
            result(FlutterError(code: "INSERT_ERROR", message: error.localizedDescription, details: nil))
            return
        }

        // Create video composition for cropping
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: width, height: height)

        // Create layer instruction with crop transform
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)

        // Get the original video transform to preserve rotation/orientation
        let originalTransform = videoTrack.preferredTransform
        let originalSize = videoTrack.naturalSize

        // Calculate the scale to fit the crop area
        let scaleX = CGFloat(width) / originalSize.width
        let scaleY = CGFloat(height) / originalSize.height

        // Combine transforms: first apply original transform, then translate for crop
        let cropTransform = CGAffineTransform(translationX: CGFloat(-x), y: CGFloat(-y))
        let finalTransform = originalTransform.concatenating(cropTransform)

        layerInstruction.setTransform(finalTransform, at: .zero)

        // Set crop rectangle for proper clipping
        layerInstruction.setCropRectangle(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)), at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // Export
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality) else {
            result(FlutterError(code: "EXPORT_ERROR", message: "Failed to create export session", details: nil))
            return
        }

        currentExportSession = exportSession

        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": true // Cropping requires re-encoding
                    ])
                case .failed:
                    result(FlutterError(code: "CROP_ERROR",
                                      message: exportSession.error?.localizedDescription ?? "Unknown error",
                                      details: nil))
                case .cancelled:
                    result(FlutterError(code: "CANCELLED", message: "Export cancelled", details: nil))
                default:
                    result(FlutterError(code: "UNKNOWN", message: "Unknown export status", details: nil))
                }
                self.currentExportSession = nil
            }
        }
    }

    private func handleProcessVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
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

        // Add tracks to composition
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(FlutterError(code: "COMPOSITION_ERROR", message: "Failed to create composition", details: nil))
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
            result(FlutterError(code: "INSERT_ERROR", message: error.localizedDescription, details: nil))
            return
        }

        var isReEncoded = false

        // Get the actual video size and current transform
        let naturalSize = videoTrack.naturalSize
        let preferredTransform = videoTrack.preferredTransform

        // Default values - start with the preferred transform
        var finalTransform = preferredTransform
        var renderSize = naturalSize

        // Handle both crop and rotation
        if let cropX = args["cropX"] as? Int,
           let cropY = args["cropY"] as? Int,
           let cropWidth = args["cropWidth"] as? Int,
           let cropHeight = args["cropHeight"] as? Int {
            isReEncoded = true


            // Set render size to crop dimensions
            renderSize = CGSize(width: CGFloat(cropWidth), height: CGFloat(cropHeight))

            // Get the oriented bounds of the video
            let orientedBounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
            let orientedSize = CGSize(width: abs(orientedBounds.width), height: abs(orientedBounds.height))

            // Build transform that properly handles crop with video orientation
            // The crop coordinates come from Flutter in the display/oriented coordinate space
            // We need to apply them correctly considering the video's orientation

            // Important: We need to handle the transform carefully for rotated videos
            // The challenge is that crop coordinates are in oriented/display space
            // but we need to apply them in a way that works with AVFoundation's transform system


            // Calculate the bounds after applying the preferred transform
            let transformedBounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)

            // Start with the preferred transform
            var transform = preferredTransform

            // Calculate the translation needed to position the crop correctly
            // After rotation, the video might be at negative coordinates
            // We need to:
            // 1. Bring it to positive coordinates if needed
            // 2. Apply the crop offset

            var translateX: CGFloat = 0
            var translateY: CGFloat = 0

            // Correct for negative positioning after rotation
            if transformedBounds.minX < 0 {
                translateX = -transformedBounds.minX
            }
            if transformedBounds.minY < 0 {
                translateY = -transformedBounds.minY
            }

            // Apply crop offset (negative because we're shifting the content)
            translateX -= CGFloat(cropX)
            translateY -= CGFloat(cropY)

            // Apply the combined translation
            transform = transform.concatenating(CGAffineTransform(translationX: translateX, y: translateY))


            // Handle rotation if specified
            if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
                let radians = CGFloat(rotateDegrees) * .pi / 180

                // Calculate the center of the current render size
                let oldCenterX = renderSize.width / 2
                let oldCenterY = renderSize.height / 2

                // For 90/270 degree rotations, we need to swap dimensions
                if abs(rotateDegrees) == 90 || abs(rotateDegrees) == 270 {
                    let newRenderSize = CGSize(width: renderSize.height, height: renderSize.width)
                    renderSize = newRenderSize
                }

                // Create rotation transform around the center
                let rotationTransform = CGAffineTransform(translationX: oldCenterX, y: oldCenterY)
                    .rotated(by: radians)
                    .translatedBy(x: -oldCenterX, y: -oldCenterY)

                // Apply rotation to the existing transform
                transform = transform.concatenating(rotationTransform)

                // After rotation, we may need to adjust position to keep video in bounds
                // Calculate where the video ends up after all transforms
                let testRect = CGRect(origin: .zero, size: CGSize(width: cropWidth, height: cropHeight))
                let finalBounds = testRect.applying(transform)


                // Correct position if video goes outside render box
                var additionalTranslateX: CGFloat = 0
                var additionalTranslateY: CGFloat = 0

                if finalBounds.minX < 0 {
                    additionalTranslateX = -finalBounds.minX
                }
                if finalBounds.minY < 0 {
                    additionalTranslateY = -finalBounds.minY
                }

                if additionalTranslateX != 0 || additionalTranslateY != 0 {
                    transform = transform.concatenating(CGAffineTransform(translationX: additionalTranslateX, y: additionalTranslateY))
                }

            }

            finalTransform = transform

        } else if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
            // Only rotation, no crop
            isReEncoded = true

            // Get the oriented size after applying preferred transform
            var orientedSize = naturalSize.applying(preferredTransform)
            orientedSize = CGSize(width: abs(orientedSize.width), height: abs(orientedSize.height))

            // Start with the preferred transform
            var transform = preferredTransform

            // For 90/270 degree rotations, swap render dimensions
            if abs(rotateDegrees) == 90 || abs(rotateDegrees) == 270 {
                renderSize = CGSize(width: orientedSize.height, height: orientedSize.width)
            } else {
                renderSize = orientedSize
            }

            // Apply rotation around the center of the oriented video
            let radians = CGFloat(rotateDegrees) * .pi / 180
            let centerX = orientedSize.width / 2
            let centerY = orientedSize.height / 2

            // Move to center, rotate, then move back
            transform = transform.translatedBy(x: centerX, y: centerY)
            transform = transform.rotated(by: radians)
            transform = transform.translatedBy(x: -centerX, y: -centerY)

            // Adjust position after rotation based on the rotation angle
            if rotateDegrees == 90 {
                transform = transform.translatedBy(x: 0, y: orientedSize.width - orientedSize.height)
            } else if rotateDegrees == 180 {
                // No additional translation needed for 180°
            } else if rotateDegrees == 270 || rotateDegrees == -90 {
                transform = transform.translatedBy(x: orientedSize.height - orientedSize.width, y: 0)
            }

            finalTransform = transform
        }

        // Apply video composition if needed
        if isReEncoded {
            videoComposition = AVMutableVideoComposition()
            videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
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
            result(FlutterError(code: "EXPORT_ERROR", message: "Failed to create export session", details: nil))
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

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    result([
                        "outputPath": outputPath,
                        "isReEncoded": isReEncoded
                    ])
                case .failed:
                    result(FlutterError(code: "PROCESS_ERROR",
                                      message: exportSession.error?.localizedDescription ?? "Unknown error",
                                      details: nil))
                case .cancelled:
                    result(FlutterError(code: "CANCELLED", message: "Export cancelled", details: nil))
                default:
                    result(FlutterError(code: "UNKNOWN", message: "Unknown export status", details: nil))
                }
                self.currentExportSession = nil
            }
        }
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

            // Calculate rotation from transform
            let angle = atan2(preferredTransform.b, preferredTransform.a)
            let rotation = Int(angle * 180 / .pi)
            info["rotation"] = rotation
        }

        if let audioTrack = tracks.first(where: { $0.mediaType == .audio }) {
            info["hasAudio"] = true
        }

        result(info)
    }
}