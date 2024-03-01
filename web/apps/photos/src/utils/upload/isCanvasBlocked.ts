//
// Canvas Blocker &
// Firefox privacy.resistFingerprinting Detector.
// (c) 2018 // JOHN OZBAY // CRYPT.EE
// MIT License

// Credits: https://github.com/johnozbay/canvas-block-detector/blob/master/isCanvasBlocked.js

//
export function isCanvasBlocked() {
    // create a 1px image data
    let blocked = false;
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");

    // some blockers just return an undefined ctx. So let's check that first.
    if (ctx) {
        const imageData = ctx.createImageData(1, 1);
        const originalImageData = imageData.data;

        // set pixels to RGB 128
        originalImageData[0] = 128;
        originalImageData[1] = 128;
        originalImageData[2] = 128;
        originalImageData[3] = 255;

        // set this to canvas
        ctx.putImageData(imageData, 1, 1);

        try {
            // now get the data back from canvas.
            const checkData = ctx.getImageData(1, 1, 1, 1).data;

            // If this is firefox, and privacy.resistFingerprinting is enabled,
            // OR a browser extension blocking the canvas,
            // This will return RGB all white (255,255,255) instead of the (128,128,128) we put.

            // so let's check the R and G to see if they're 255 or 128 (matching what we've initially set)
            if (
                originalImageData[0] !== checkData[0] &&
                originalImageData[1] !== checkData[1]
            ) {
                blocked = true;
            }
        } catch (error) {
            // some extensions will return getImageData null. this is to account for that.
            blocked = true;
        }
    } else {
        blocked = true;
    }
    return blocked;
}
