import { Readable } from 'stream';
import * as fs from 'fs';
import * as electron from 'electron';

const { ipcRenderer } = electron;

const responseToReadable = (fileStream: any) => {
    const reader = fileStream.getReader();
    const rs = new Readable();
    rs._read = async () => {
        const result = await reader.read();
        console.log(result);
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
    }
};

var windowObject: any = window;
windowObject['ElectronAPIs'] = {
    saveToDisk,
    selectDirectory,
};
