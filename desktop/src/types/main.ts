import { FILE_PATH_TYPE } from "./ipc";



/* eslint-disable no-unused-vars */
export const FILE_PATH_KEYS: {
    [k in FILE_PATH_TYPE]: keyof UploadStoreType;
} = {
    [FILE_PATH_TYPE.ZIPS]: "zipPaths",
    [FILE_PATH_TYPE.FILES]: "filePaths",
};

