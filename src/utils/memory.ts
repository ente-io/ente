import ElectronLog from 'electron-log';

const FIVE_MINUTES = 30 * 1000;

async function logMainProcessStats() {
    const systemMemoryInfo = process.getSystemMemoryInfo();
    const cpuUsage = process.getCPUUsage();
    const processMemoryInfo = await process.getProcessMemoryInfo();

    ElectronLog.log('main process stats', {
        systemMemoryInfo,
        cpuUsage,
        processMemoryInfo,
    });
}

async function logRendererProcessStats() {
    const blinkMemoryInfo = process.getBlinkMemoryInfo();
    ElectronLog.log('renderer process stats', {
        blinkMemoryInfo,
    });
}

export function setupMainProcessStatsLogger() {
    setInterval(logMainProcessStats, FIVE_MINUTES);
}

export function setupRendererProcessStatsLogger() {
    setInterval(logRendererProcessStats, FIVE_MINUTES);
}
