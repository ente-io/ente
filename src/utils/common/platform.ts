export function isPlatform(platform: 'mac' | 'windows' | 'linux') {
    if (process.platform === 'darwin') {
        return platform === 'mac';
    } else if (process.platform === 'win32') {
        return platform === 'windows';
    } else if (process.platform === 'linux') {
        return platform === 'linux';
    } else {
        return false;
    }
}
