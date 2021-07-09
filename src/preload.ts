import { Readable } from 'stream';
import * as fs from 'promise-fs';
import * as electron from 'electron';

const { ipcRenderer } = electron;

const EXPORT_FILE_NAME = 'export.txt';

enum RecordType {
    SUCCESS = "success",
    FAILED = "failed"
}
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

const updateExportRecord = async (dir: string, dataToAppend: string, type = RecordType.SUCCESS) => {
    const filepath = `${dir}/${EXPORT_FILE_NAME}`;
    let file = null;
    try {
        file = await fs.readFile(filepath, 'utf-8');
    } catch (e) {
        file = '';
    }
    file = file + `${type}@${dataToAppend}\n`;
    await fs.writeFile(filepath, file);
};

const getExportedFiles = async (dir: string, type = RecordType.SUCCESS) => {
    try {
        const filepath = `${dir}/${EXPORT_FILE_NAME}`;

        const fileList = (await fs.readFile(filepath, 'utf-8')).split('\n');
        const resp = new Set();
        fileList.forEach((file) => {
            const splits = file.split("@");
            if (splits[0] === type) {
                resp.add(splits[1])
            }
        })
        return resp;
    } catch (e) {
        return new Set<string>();
    }
};

const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};
const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};

const registerStartExportListener = (startExport: () => void) => {
    ipcRenderer.removeAllListeners("start-export");
    ipcRenderer.on('start-export', () => startExport());
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

const windowObject: any = window;
windowObject['ElectronAPIs'] = {
    checkExistsAndCreateCollectionDir,
    saveStreamToDisk,
    saveFileToDisk,
    selectRootDirectory,
    updateExportRecord,
    getExportedFiles,
    sendNotification,
    showOnTray,
    reloadWindow,
    registerStartExportListener,
    registerStopExportListener,
    registerPauseExportListener,
    registerRetryFailedExportListener,
};
