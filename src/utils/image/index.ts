export function resizeToSquare(img: ImageBitmap, size: number) {
    const scale = size / Math.max(img.height, img.width);
    const width = scale * img.width;
    const height = scale * img.height;
    // if (!offscreen) {
    const offscreen = new OffscreenCanvas(size, size);
    // }
    offscreen.getContext('2d').drawImage(img, 0, 0, width, height);

    return { image: offscreen.transferToImageBitmap(), width, height };
}

export function transform(
    img: ImageBitmap,
    affineMat: number[][],
    outputWidth: number,
    outputHeight: number
) {
    const offscreen = new OffscreenCanvas(outputWidth, outputHeight);
    const context = offscreen.getContext('2d');

    context.transform(
        affineMat[0][0],
        affineMat[1][0],
        affineMat[0][1],
        affineMat[1][1],
        affineMat[0][2],
        affineMat[1][2]
    );

    context.drawImage(img, 0, 0);
    return offscreen.transferToImageBitmap();
}
