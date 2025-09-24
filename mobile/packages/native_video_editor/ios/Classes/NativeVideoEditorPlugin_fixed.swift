// Key fix for processVideo to handle rotation + crop correctly
// This is a partial snippet showing the critical fix

private func processVideo(args: [String: Any], result: @escaping FlutterResult) {
    // ... existing code for setup ...

    // Track the current transform and render size
    var currentTransform = videoTrack.preferredTransform
    var currentRenderSize = videoTrack.naturalSize

    // Handle rotation FIRST
    if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
        isReEncoded = true

        if videoComposition == nil {
            videoComposition = AVMutableVideoComposition()
            videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
        }

        // Apply rotation to the current transform
        switch rotateDegrees {
        case 90:
            currentTransform = currentTransform.concatenating(
                CGAffineTransform(rotationAngle: .pi / 2)
            )
            currentRenderSize = CGSize(width: currentRenderSize.height, height: currentRenderSize.width)
        case 180:
            currentTransform = currentTransform.concatenating(
                CGAffineTransform(rotationAngle: .pi)
            )
        case 270:
            currentTransform = currentTransform.concatenating(
                CGAffineTransform(rotationAngle: -.pi / 2)
            )
            currentRenderSize = CGSize(width: currentRenderSize.height, height: currentRenderSize.width)
        default:
            break
        }

        videoComposition!.renderSize = currentRenderSize

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(currentTransform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition!.instructions = [instruction]
    }

    // Handle crop AFTER rotation
    if let cropRect = args["cropRect"] as? [String: Double] {
        let cropX = Int(cropRect["x"] ?? 0)
        let cropY = Int(cropRect["y"] ?? 0)
        let cropWidth = Int(cropRect["width"] ?? Double(currentRenderSize.width))
        let cropHeight = Int(cropRect["height"] ?? Double(currentRenderSize.height))

        isReEncoded = true

        if videoComposition == nil {
            videoComposition = AVMutableVideoComposition()
            videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
        }

        // Update render size for crop
        videoComposition!.renderSize = CGSize(width: cropWidth, height: cropHeight)

        // Apply crop transform to the current transform (which may already include rotation)
        let cropTransform = CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY))
        currentTransform = currentTransform.concatenating(cropTransform)

        let instruction: AVMutableVideoCompositionInstruction
        if let existingInstructions = videoComposition!.instructions as? [AVMutableVideoCompositionInstruction],
           !existingInstructions.isEmpty {
            instruction = existingInstructions[0]
        } else {
            instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        }

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(currentTransform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition!.instructions = [instruction]
    }

    // ... rest of export code ...
}