const WAIT_FOR_VIDEO_PLAYBACK = 1 * 1000;

export async function isPlaybackPossible(url: string): Promise<boolean> {
    return await new Promise((resolve) => {
        const t = setTimeout(() => {
            resolve(false);
        }, WAIT_FOR_VIDEO_PLAYBACK);

        const video = document.createElement("video");
        video.addEventListener("canplay", function () {
            clearTimeout(t);
            video.remove(); // Clean up the video element
            // also check for duration > 0 to make sure it is not a broken video
            if (video.duration > 0) {
                resolve(true);
            } else {
                resolve(false);
            }
        });
        video.addEventListener("error", function () {
            clearTimeout(t);
            video.remove();
            resolve(false);
        });

        video.src = url;
    });
}
