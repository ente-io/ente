import isElectron from 'is-electron';
import { ElectronFile } from 'types/upload';
import {
    AnalysisResult,
    UPLOAD_TYPE,
    NULL_ANALYSIS_RESULT,
} from 'types/upload';

export function analyseUploadFiles(
    uploadFiles: File[] | ElectronFile[],
    uploadType: UPLOAD_TYPE
): AnalysisResult {
    if (isElectron() && uploadType === UPLOAD_TYPE.FILES) {
        return NULL_ANALYSIS_RESULT;
    }

    const paths: string[] = uploadFiles.map((file) => file['path']);
    const getCharCount = (str: string) => (str.match(/\//g) ?? []).length;
    paths.sort((path1, path2) => getCharCount(path1) - getCharCount(path2));
    const firstPath = paths[0];
    const lastPath = paths[paths.length - 1];

    const L = firstPath.length;
    let i = 0;
    const firstFileFolder = firstPath.substring(0, firstPath.lastIndexOf('/'));
    const lastFileFolder = lastPath.substring(0, lastPath.lastIndexOf('/'));
    while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
    let commonPathPrefix = firstPath.substring(0, i);

    if (commonPathPrefix) {
        commonPathPrefix = commonPathPrefix.substring(
            0,
            commonPathPrefix.lastIndexOf('/')
        );
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substring(
                commonPathPrefix.lastIndexOf('/') + 1
            );
        }
    }
    return {
        suggestedCollectionName: commonPathPrefix || null,
        multipleFolders: firstFileFolder !== lastFileFolder,
    };
}
