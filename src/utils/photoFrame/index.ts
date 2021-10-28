const WAIT_FOR_VIDEO_PLAYBACK = 1 * 1000;

export async function isPlaybackPossible(url: string): Promise<boolean> {
    return await new Promise((resolve) => {
        const t = setTimeout(() => {
            resolve(false);
        }, WAIT_FOR_VIDEO_PLAYBACK);
        const video = document.createElement('video');
        video.addEventListener('canplay', function () {
            clearTimeout(t);
            resolve(true);
        });
        video.src = url;
    });
}
