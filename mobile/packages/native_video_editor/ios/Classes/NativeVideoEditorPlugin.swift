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

        // Apply crop transform
        let transform = CGAffineTransform(translationX: CGFloat(-x), y: CGFloat(-y))
        layerInstruction.setTransform(transform, at: .zero)

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

        // Handle rotation and crop (requires video composition)
        if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
            isReEncoded = true
            // Create video composition if needed
            if videoComposition == nil {
                videoComposition = AVMutableVideoComposition()
                videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
            }

            // Apply rotation transform
            var transform = CGAffineTransform.identity
            let naturalSize = videoTrack.naturalSize
            var renderSize = naturalSize

            switch rotateDegrees {
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
                break
            }

            videoComposition!.renderSize = renderSize

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(transform, at: .zero)

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

        Task {
            do {
                let duration = try await asset.load(.duration)
                let tracks = try await asset.load(.tracks)

                var info: [String: Any] = [
                    "duration": CMTimeGetSeconds(duration) * 1000, // Convert to milliseconds
                ]

                if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                    let naturalSize = try await videoTrack.load(.naturalSize)
                    let preferredTransform = try await videoTrack.load(.preferredTransform)
                    let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)

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

                DispatchQueue.main.async {
                    result(info)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "INFO_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}