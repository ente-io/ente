declare global {
    interface Window {
        chrome: any;
    }
}

export const isChromecastSupported = () => {
    return !!(
        window.chrome &&
        window.chrome.cast &&
        window.chrome.cast.isAvailable
    );
};
