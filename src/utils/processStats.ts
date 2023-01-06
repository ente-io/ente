import ElectronLog from 'electron-log';
import { webFrame } from 'electron/renderer';

const LOGGING_INTERVAL_IN_MICROSECONDS = 1 * 1000;

async function logMainProcessStats() {
    const systemMemoryInfo = process.getSystemMemoryInfo();
    const cpuUsage = process.getCPUUsage();
    const processMemoryInfo = await process.getProcessMemoryInfo();
    const heapStatistics = process.getHeapStatistics();

    ElectronLog.log('main process stats', {
        systemMemoryInfo,
        cpuUsage,
        processMemoryInfo,
        heapStatistics,
    });
}

async function logRendererProcessStats() {
    const blinkMemoryInfo = process.getBlinkMemoryInfo();
    const heapStatistics = process.getHeapStatistics();
    const processMemoryInfo = process.getProcessMemoryInfo();
    const webFrameResourceUsage = webFrame.getResourceUsage();
    ElectronLog.log('renderer process stats', {
        blinkMemoryInfo,
        heapStatistics,
        processMemoryInfo,
        webFrameResourceUsage,
    });
}

export function setupMainProcessStatsLogger() {
    setInterval(logMainProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}

export function setupRendererProcessStatsLogger() {
    setInterval(logRendererProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}
