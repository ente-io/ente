import { Readable } from 'stream';
import * as fs from 'promise-fs';
import * as electron from 'electron';

const { ipcRenderer } = electron;

const EXPORT_FILE_NAME = 'export.txt';

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

const updateExportRecord = async (dir: string, dataToAppend: string) => {
    const filepath = `${dir}/${EXPORT_FILE_NAME}`;
    let file = null;
    try {
        file = await fs.readFile(filepath, 'utf-8');
    } catch (e) {
        file = '';
    }
    file = file + `${dataToAppend}\n`;
    await fs.writeFile(filepath, file);
};

const getExportedFiles = async (dir: string) => {
    try {
        const filepath = `${dir}/${EXPORT_FILE_NAME}`;

        let fileList = (await fs.readFile(filepath, 'utf-8')).split('\n');

        return new Set<string>(fileList);
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

const registerStopExportListener = (abortExport: Function) => {
    ipcRenderer.on('stop-export', () => abortExport());
};

const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

var windowObject: any = window;
windowObject['ElectronAPIs'] = {
    checkExistsAndCreateCollectionDir,
    saveStreamToDisk,
    saveFileToDisk,
    selectRootDirectory,
    updateExportRecord,
    getExportedFiles,
    sendNotification,
    showOnTray,
    registerStopExportListener,
    reloadWindow,
};
