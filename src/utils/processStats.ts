import ElectronLog from 'electron-log';
import { webFrame } from 'electron/renderer';

const LOGGING_INTERVAL_IN_MICROSECONDS = 30 * 1000; // 30 seconds

const SPIKE_DETECTION_INTERVAL_IN_MICROSECONDS = 1 * 1000; // 1 seconds

const MEMORY_DIFF_IN_KILOBYTES_CONSIDERED_AS_SPIKE = 500 * 1024; // 500 MB

let previousMemoryUsage = 0;

async function logMainProcessStats() {
    const processMemoryInfo = await process.getProcessMemoryInfo();
    const normalizedProcessMemoryInfo = await getNormalizedProcessMemoryInfo(
        processMemoryInfo
    );
    const cpuUsage = process.getCPUUsage();
    const heapStatistics = getNormalizedHeapStatistics();

    ElectronLog.log('main process stats', {
        processMemoryInfo: normalizedProcessMemoryInfo,
        heapStatistics,
        cpuUsage,
    });
}

async function logSpikeMemoryUsage() {
    const processMemoryInfo = await process.getProcessMemoryInfo();
    const currentMemoryUsage = Math.max(
        processMemoryInfo.residentSet,
        processMemoryInfo.private
    );
    const isSpiking =
        currentMemoryUsage - previousMemoryUsage >=
        MEMORY_DIFF_IN_KILOBYTES_CONSIDERED_AS_SPIKE;

    if (isSpiking) {
        const normalizedProcessMemoryInfo =
            await getNormalizedProcessMemoryInfo(processMemoryInfo);
        const cpuUsage = process.getCPUUsage();
        const heapStatistics = getNormalizedHeapStatistics();

        ElectronLog.log('main process stats', {
            processMemoryInfo: normalizedProcessMemoryInfo,
            heapStatistics,
            cpuUsage,
        });
    }
    previousMemoryUsage = currentMemoryUsage;
}

async function logRendererProcessStats() {
    const blinkMemoryInfo = getNormalizedBlinkMemoryInfo();
    const heapStatistics = getNormalizedHeapStatistics();
    const webFrameResourceUsage = getNormalizedWebFrameResourceUsage();
    ElectronLog.log('renderer process stats', {
        blinkMemoryInfo,
        heapStatistics,
        webFrameResourceUsage,
    });
}

export function setupMainProcessStatsLogger() {
    setInterval(logSpikeMemoryUsage, SPIKE_DETECTION_INTERVAL_IN_MICROSECONDS);
    setInterval(logMainProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}

export function setupRendererProcessStatsLogger() {
    setInterval(logRendererProcessStats, LOGGING_INTERVAL_IN_MICROSECONDS);
}

const getNormalizedProcessMemoryInfo = async (
    processMemoryInfo: Electron.ProcessMemoryInfo
) => {
    return {
        residentSet: convertBytesToHumanReadable(
            processMemoryInfo.residentSet * 1024
        ),
        private: convertBytesToHumanReadable(processMemoryInfo.private * 1024),
        shared: convertBytesToHumanReadable(processMemoryInfo.shared * 1024),
    };
};

const getNormalizedBlinkMemoryInfo = () => {
    const blinkMemoryInfo = process.getBlinkMemoryInfo();
    return {
        allocated: convertBytesToHumanReadable(
            blinkMemoryInfo.allocated * 1024
        ),
        total: convertBytesToHumanReadable(blinkMemoryInfo.total * 1024),
    };
};

const getNormalizedHeapStatistics = () => {
    const heapStatistics = process.getHeapStatistics();
    return {
        totalHeapSize: convertBytesToHumanReadable(
            heapStatistics.totalHeapSize * 1024
        ),
        totalHeapSizeExecutable: convertBytesToHumanReadable(
            heapStatistics.totalHeapSizeExecutable * 1024
        ),
        totalPhysicalSize: convertBytesToHumanReadable(
            heapStatistics.totalPhysicalSize * 1024
        ),
        totalAvailableSize: convertBytesToHumanReadable(
            heapStatistics.totalAvailableSize * 1024
        ),
        usedHeapSize: convertBytesToHumanReadable(
            heapStatistics.usedHeapSize * 1024
        ),

        heapSizeLimit: convertBytesToHumanReadable(
            heapStatistics.heapSizeLimit * 1024
        ),
        mallocedMemory: convertBytesToHumanReadable(
            heapStatistics.mallocedMemory * 1024
        ),
        peakMallocedMemory: convertBytesToHumanReadable(
            heapStatistics.peakMallocedMemory * 1024
        ),
        doesZapGarbage: heapStatistics.doesZapGarbage,
    };
};

const getNormalizedWebFrameResourceUsage = () => {
    const webFrameResourceUsage = webFrame.getResourceUsage();
    return {
        images: {
            count: webFrameResourceUsage.images.count,
            size: convertBytesToHumanReadable(
                webFrameResourceUsage.images.size
            ),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.images.liveSize
            ),
        },
        scripts: {
            count: webFrameResourceUsage.scripts.count,
            size: convertBytesToHumanReadable(
                webFrameResourceUsage.scripts.size
            ),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.scripts.liveSize
            ),
        },
        cssStyleSheets: {
            count: webFrameResourceUsage.cssStyleSheets.count,
            size: convertBytesToHumanReadable(
                webFrameResourceUsage.cssStyleSheets.size
            ),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.cssStyleSheets.liveSize
            ),
        },
        xslStyleSheets: {
            count: webFrameResourceUsage.xslStyleSheets.count,
            size: convertBytesToHumanReadable(
                webFrameResourceUsage.xslStyleSheets.size
            ),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.xslStyleSheets.liveSize
            ),
        },
        fonts: {
            count: webFrameResourceUsage.fonts.count,
            size: convertBytesToHumanReadable(webFrameResourceUsage.fonts.size),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.fonts.liveSize
            ),
        },
        other: {
            count: webFrameResourceUsage.other.count,
            size: convertBytesToHumanReadable(webFrameResourceUsage.other.size),
            liveSize: convertBytesToHumanReadable(
                webFrameResourceUsage.other.liveSize
            ),
        },
    };
};

function convertBytesToHumanReadable(bytes: number, precision = 2): string {
    if (bytes === 0 || isNaN(bytes)) {
        return '0 MB';
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + ' ' + sizes[i];
}
