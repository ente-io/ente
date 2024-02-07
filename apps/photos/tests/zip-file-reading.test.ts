import { DataStream } from 'types/upload';
import ElectronAPIs from '@ente/shared/electron';
import { FILE_READER_CHUNK_SIZE, PICKED_UPLOAD_TYPE } from 'constants/upload';
import { getFileStream, getElectronFileStream } from 'services/readerService';
import { getFileNameSize } from '@ente/shared/logging/web';
import isElectron from 'is-electron';
import { getImportSuggestion } from 'utils/upload';

// This was for used to verify that converting from the browser readable stream
// to the node readable stream correctly handles files that align on the 4 MB
// data boundary. This expects a zip file containing random files of various
// sizes starting from 1M to 20M.
export const testZipFileReading = async () => {
    try {
        if (!isElectron()) {
            console.log('testZipFileReading Check is for desktop only');
            return;
        }
        if (!process.env.NEXT_PUBLIC_FILE_READING_TEST_ZIP_PATH) {
            throw Error(
                'upload test failed NEXT_PUBLIC_FILE_READING_TEST_ZIP_PATH missing'
            );
        }
        const files = await ElectronAPIs.getElectronFilesFromGoogleZip(
            process.env.NEXT_PUBLIC_FILE_READING_TEST_ZIP_PATH
        );
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

// This was used when fixing a bug around handling a zip file that has a photo
// at the root.
export const testZipWithRootFileReadingTest = async () => {
    try {
        if (!isElectron()) {
            console.log('testZipFileReading Check is for desktop only');
            return;
        }
        if (!process.env.NEXT_PUBLIC_ZIP_WITH_ROOT_FILE_PATH) {
            throw Error(
                'upload test failed NEXT_PUBLIC_ZIP_WITH_ROOT_FILE_PATH missing'
            );
        }
        const files = await ElectronAPIs.getElectronFilesFromGoogleZip(
            process.env.NEXT_PUBLIC_ZIP_WITH_ROOT_FILE_PATH
        );

        const importSuggestion = getImportSuggestion(
            PICKED_UPLOAD_TYPE.ZIPS,
            files
        );
        if (!importSuggestion.rootFolderName) {
            throw Error(
                `testZipWithRootFileReadingTest Check failed ❌
            rootFolderName is missing`
            );
        }
        console.log('testZipWithRootFileReadingTest passed ✅');
    } catch (e) {
        console.log(e);
    }
};
