import { EnteFile } from 'types/file';
import { getEndpoint } from 'utils/common/apiUtil';
import { decryptFile, sortFiles, mergeMetadata } from 'utils/file';
import { logError } from 'utils/sentry';
import HTTPService from './HTTPService';

const ENDPOINT = getEndpoint();

export const getSharedCollectionFiles = async (
    token: string,
    collectionKey: string,
    setFiles: (files: EnteFile[]) => void
) => {
    try {
        if (!token || !collectionKey) {
            throw Error('token or collectionKey missing');
        }
        const decryptedFiles: EnteFile[] = [];
        let time = 0;
        let resp;
        do {
            resp = await HTTPService.get(
                `${ENDPOINT}/public-collection/diff`,
                {
                    sinceTime: time,
                },
                {
                    'X-Auth-Access-Token': token,
                }
            );

            decryptedFiles.push(
                ...(await Promise.all(
                    resp.data.diff.map(async (file: EnteFile) => {
                        if (!file.isDeleted) {
                            file = await decryptFile(file, collectionKey);
                        }
                        return file;
                    }) as Promise<EnteFile>[]
                ))
            );

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setFiles(
                sortFiles(
                    mergeMetadata(
                        decryptedFiles.filter((item) => !item.isDeleted)
                    )
                )
            );
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        logError(e, 'Get files failed');
    }
    return [];
};
