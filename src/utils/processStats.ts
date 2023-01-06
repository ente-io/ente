import ElectronLog from 'electron-log';
import { webFrame } from 'electron/renderer';

const LOGGING_INTERVAL_IN_MICROSECONDS = 1 * 1000;

async function logMainProcessStats() {
    const processMemoryInfo = await process.getProcessMemoryInfo();
    const normalizedProcessMemoryInfo = await getNormalizedProcessMemoryInfo(
        processMemoryInfo
    );
    const systemMemoryInfo = process.getSystemMemoryInfo();
    const normalizedSystemMemoryInfo =
        getNormalizedSystemMemoryInfo(systemMemoryInfo);
    const cpuUsage = process.getCPUUsage();
    const heapStatistics = process.getHeapStatistics();

    ElectronLog.log('main process stats', {
        processMemoryInfo: normalizedProcessMemoryInfo,
        systemMemoryInfo: normalizedSystemMemoryInfo,
        heapStatistics,
        cpuUsage,
    });
}

async function logRendererProcessStats() {
    const blinkMemoryInfo = getNormalizedBlinkMemoryInfo();
    const heapStatistics = process.getHeapStatistics();
    const webFrameResourceUsage = webFrame.getResourceUsage();
    ElectronLog.log('renderer process stats', {
        blinkMemoryInfo,
        heapStatistics,
        webFrameResourceUsage,
    });
}

export function setupMainProcessStatsLogger() {
    setInterval(logMainProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}

export function setupRendererProcessStatsLogger() {
    setInterval(logRendererProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}

const getNormalizedProcessMemoryInfo = async (
    processMemoryInfo: Electron.ProcessMemoryInfo
) => {
    return {
        residentSet: convertBytesToHumanReadable(processMemoryInfo.residentSet),
        private: convertBytesToHumanReadable(processMemoryInfo.private),
        shared: convertBytesToHumanReadable(processMemoryInfo.shared),
    };
};

const getNormalizedSystemMemoryInfo = (
    systemMemoryInfo: Electron.SystemMemoryInfo
) => {
    return {
        total: convertBytesToHumanReadable(systemMemoryInfo.total),
        free: convertBytesToHumanReadable(systemMemoryInfo.free),
        swapTotal: convertBytesToHumanReadable(systemMemoryInfo.swapTotal),
        swapFree: convertBytesToHumanReadable(systemMemoryInfo.swapFree),
    };
};

const getNormalizedBlinkMemoryInfo = () => {
    const blinkMemoryInfo = process.getBlinkMemoryInfo();
    return {
        allocated: convertBytesToHumanReadable(blinkMemoryInfo.allocated),
        total: convertBytesToHumanReadable(blinkMemoryInfo.total),
    };
};

function convertBytesToHumanReadable(bytes: number, precision = 2): string {
    if (bytes === 0) {
        return '0 MB';
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + ' ' + sizes[i];
}
