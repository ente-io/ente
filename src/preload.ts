import { Readable } from 'stream';
import * as fs from 'promise-fs';
import * as electron from 'electron';

const { ipcRenderer } = electron;

const EXPORT_FILE_NAME = 'export_status.json';

const responseToReadable = (fileStream: any) => {
    const reader = fileStream.getReader();
    const rs = new Readable();
    rs._read = async () => {
        const result = await reader.read();
        if (!result.done) {
            rs.push(Buffer.from(result.value));
        } else {
            rs.push(null);
            return;
        }
    };
    return rs;
};

const checkExistsAndCreateCollectionDir = async (dirPath: string) => {
    if (!fs.existsSync(dirPath)) {
        await fs.mkdir(dirPath);
    }
};

const saveStreamToDisk = (path: string, fileStream: ReadableStream<any>) => {
    const writeable = fs.createWriteStream(path);
    const readable = responseToReadable(fileStream);
    readable.pipe(writeable);
};

const saveFileToDisk = async (path: string, file: any) => {
    await fs.writeFile(path, file);
};

const selectRootDirectory = async () => {
    try {
        return await ipcRenderer.sendSync('select-dir');
    } catch (e) {
        console.error(e);
        throw e;
    }
};



const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};
const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};

const registerResumeExportListener = (resumeExport: () => void) => {
    ipcRenderer.removeAllListeners("resume-export");
    ipcRenderer.on('resume-export', () => resumeExport());
};
const registerStopExportListener = (abortExport: () => void) => {
    ipcRenderer.removeAllListeners("stop-export");
    ipcRenderer.on('stop-export', () => abortExport());
};

const registerPauseExportListener = (pauseExport: () => void) => {
    ipcRenderer.removeAllListeners("pause-export");
    ipcRenderer.on('pause-export', () => pauseExport());
};

const registerRetryFailedExportListener = (retryFailedExport: () => void) => {
    ipcRenderer.removeAllListeners("retry-export");
    ipcRenderer.on('retry-export', () => retryFailedExport());
};

const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

const getExportRecord = async (dir: string) => {
    try {
        const filepath = `${dir}/${EXPORT_FILE_NAME}`;
        const recordFile = await fs.readFile(filepath, 'utf-8');
        return recordFile;
    } catch (e) {
        // ignore exportFile missing
        console.log(e);
    }
};

const setExportRecord = async (dir: string, data: string) => {
    
    const filepath = `${dir}/${EXPORT_FILE_NAME}`;
    await fs.writeFile(filepath, data);
};

const windowObject: any = window;
windowObject['ElectronAPIs'] = {
    checkExistsAndCreateCollectionDir,
    saveStreamToDisk,
    saveFileToDisk,
    selectRootDirectory,
    sendNotification,
    showOnTray,
    reloadWindow,
    registerResumeExportListener,
    registerStopExportListener,
    registerPauseExportListener,
    registerRetryFailedExportListener,
    getExportRecord,
    setExportRecord
};
