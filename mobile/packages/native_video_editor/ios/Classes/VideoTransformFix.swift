// Simplified approach for video transformation
// Key changes:
// 1. Simpler rotation transforms without complex concatenation
// 2. Proper render size calculation
// 3. Clear transform order

// In processVideo method, replace rotation and crop handling:

// Track transform and size
var finalTransform = videoTrack.preferredTransform
var renderSize = videoTrack.naturalSize

// Handle rotation
if let rotateDegrees = args["rotateDegrees"] as? Int, rotateDegrees != 0 {
    isReEncoded = true

    if videoComposition == nil {
        videoComposition = AVMutableVideoComposition()
        videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
    }

    let naturalSize = videoTrack.naturalSize

    // Apply simple rotation transforms
    switch rotateDegrees {
    case 90:
        finalTransform = CGAffineTransform(rotationAngle: .pi / 2)
            .translatedBy(x: 0, y: -naturalSize.width)
        renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
    case 180:
        finalTransform = CGAffineTransform(rotationAngle: .pi)
            .translatedBy(x: -naturalSize.width, y: -naturalSize.height)
    case 270:
        finalTransform = CGAffineTransform(rotationAngle: -.pi / 2)
            .translatedBy(x: -naturalSize.height, y: 0)
        renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
    default:
        break
    }
}

// Handle crop
if let cropX = args["cropX"] as? Int,
   let cropY = args["cropY"] as? Int,
   let cropWidth = args["cropWidth"] as? Int,
   let cropHeight = args["cropHeight"] as? Int {
    isReEncoded = true

    if videoComposition == nil {
        videoComposition = AVMutableVideoComposition()
        videoComposition!.frameDuration = CMTime(value: 1, timescale: 30)
    }

    // Apply crop by translating and setting render size
    finalTransform = finalTransform.translatedBy(x: CGFloat(-cropX), y: CGFloat(-cropY))
    renderSize = CGSize(width: cropWidth, height: cropHeight)
}

// Apply the final composition
if videoComposition != nil {
    videoComposition!.renderSize = renderSize

    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
    layerInstruction.setTransform(finalTransform, at: .zero)

    instruction.layerInstructions = [layerInstruction]
    videoComposition!.instructions = [instruction]
}