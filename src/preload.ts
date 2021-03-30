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

const saveToDisk = (path: string, fileStream: ReadableStream<any>) => {
    const writeable = fs.createWriteStream(path);
    const readable = responseToReadable(fileStream);
    readable.pipe(writeable);
};

const selectDirectory = async () => {
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
const showOnTray = (item: any[]) => {
    ipcRenderer.send('update-tray', item);
};

var windowObject: any = window;
windowObject['ElectronAPIs'] = {
    saveToDisk,
    selectDirectory,
    updateExportRecord,
    getExportedFiles,
    sendNotification,
    showOnTray,
};
