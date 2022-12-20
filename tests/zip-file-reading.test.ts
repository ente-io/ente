import { DataStream } from 'types/upload';
import ImportService from 'services/importService';
import { FILE_READER_CHUNK_SIZE } from 'constants/upload';
import { getFileStream, getElectronFileStream } from 'services/readerService';
import { getFileNameSize } from 'utils/logging';

const openZipUploadFilePicker = async () => {
    const response = await ImportService.showUploadZipDialog();
    return response.files;
};

export const testZipFileReading = async () => {
    try {
        const files = await openZipUploadFilePicker();
        if (!files?.length) {
            throw Error(
                `testZipFileReading Check failed ❌ 
                No files selected`
            );
        }
        console.log('test zip file reading check started');
        let i = 0;
        for (const file of files) {
            i++;
            let filedata: DataStream;
            if (file instanceof File) {
                filedata = getFileStream(file, FILE_READER_CHUNK_SIZE);
            } else {
                filedata = await getElectronFileStream(
                    file,
                    FILE_READER_CHUNK_SIZE
                );
            }
            const streamReader = filedata.stream.getReader();
            for (let i = 0; i < filedata.chunkCount; i++) {
                const { done } = await streamReader.read();
                if (done) {
                    throw Error(
                        `testZipFileReading Check failed ❌
                        ${getFileNameSize(
                            file
                        )} less than expected chunks, expected: ${
                            filedata.chunkCount
                        }, got ${i - 1}`
                    );
                }
            }
            const { done } = await streamReader.read();

            if (!done) {
                throw Error(
                    `testZipFileReading Check failed ❌
                     ${getFileNameSize(
                         file
                     )}  more than expected chunks, expected: ${
                        filedata.chunkCount
                    }`
                );
            }
            console.log(`${i}/${files.length} passed ✅`);
        }
        console.log('test zip file reading check passed ✅');
    } catch (e) {
        console.log(e);
    }
};
