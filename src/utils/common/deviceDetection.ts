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
        return 'wp';
    }

    if (/android/i.test(userAgent)) {
        return 'android';
    }

    // iOS detection from: http://stackoverflow.com/a/9039885/177710
    if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
        return 'ios';
    }

    return 'unknown';
};

export default GetDeviceOS;
