export enum OS {
    WP = 'wp',
    ANDROID = 'android',
    IOS = 'ios',
    UNKNOWN = 'unknown',
}

declare global {
    interface Window {
        opera: any;
        MSStream: any;
    }
}

const GetDeviceOS = () => {
    let userAgent = '';
    if (
        typeof window !== 'undefined' &&
        typeof window.navigator !== 'undefined'
    ) {
        userAgent = navigator.userAgent || navigator.vendor || window.opera;
    }
    // Windows Phone must come first because its UA also contains "Android"
    if (/windows phone/i.test(userAgent)) {
        return OS.WP;
    }

    if (/android/i.test(userAgent)) {
        return OS.ANDROID;
    }

    // iOS detection from: http://stackoverflow.com/a/9039885/177710
    if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
        return OS.IOS;
    }

    return OS.UNKNOWN;
};

export default GetDeviceOS;
