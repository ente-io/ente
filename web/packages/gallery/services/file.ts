/* TODO: Audit this file */
/* eslint-disable @typescript-eslint/ban-ts-comment */

import { encryptMetadataJSON } from "@/base/crypto";
import { apiURL } from "@/base/origins";
import type {
    EncryptedMagicMetadata,
    EnteFile,
    FileWithUpdatedMagicMetadata,
    FileWithUpdatedPublicMagicMetadata,
} from "@/media/file";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

export interface UpdateMagicMetadataRequest {
    id: number;
    magicMetadata: EncryptedMagicMetadata;
}

interface BulkUpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

export const updateFileMagicMetadata = async (
    fileWithUpdatedMagicMetadataList: FileWithUpdatedMagicMetadata[],
) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    for (const {
        file,
        updatedMagicMetadata,
    } of fileWithUpdatedMagicMetadataList) {
        const { encryptedDataB64, decryptionHeaderB64 } =
            await encryptMetadataJSON({
                jsonValue: updatedMagicMetadata.data,
                keyB64: file.key,
            });
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatedMagicMetadata.version,
                count: updatedMagicMetadata.count,
                data: encryptedDataB64,
                header: decryptionHeaderB64,
            },
        });
    }
    await HTTPService.put(
        await apiURL("/files/magic-metadata"),
        reqBody,
        // @ts-ignore
        null,
        {
            "X-Auth-Token": token,
        },
    );
    return fileWithUpdatedMagicMetadataList.map(
        ({ file, updatedMagicMetadata }): EnteFile => ({
            ...file,
            magicMetadata: {
                ...updatedMagicMetadata,
                version: updatedMagicMetadata.version + 1,
            },
        }),
    );
};

export const updateFilePublicMagicMetadata = async (
    fileWithUpdatedPublicMagicMetadataList: FileWithUpdatedPublicMagicMetadata[],
): Promise<EnteFile[]> => {
    const token = getToken();
    if (!token) {
        // @ts-ignore
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    for (const {
        file,
        updatedPublicMagicMetadata,
    } of fileWithUpdatedPublicMagicMetadataList) {
        const { encryptedDataB64, decryptionHeaderB64 } =
            await encryptMetadataJSON({
                jsonValue: updatedPublicMagicMetadata.data,
                keyB64: file.key,
            });
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatedPublicMagicMetadata.version,
                count: updatedPublicMagicMetadata.count,
                data: encryptedDataB64,
                header: decryptionHeaderB64,
            },
        });
    }
    await HTTPService.put(
        await apiURL("/files/public-magic-metadata"),
        reqBody,
        // @ts-ignore
        null,
        {
            "X-Auth-Token": token,
        },
    );
    return fileWithUpdatedPublicMagicMetadataList.map(
        ({ file, updatedPublicMagicMetadata }): EnteFile => ({
            ...file,
            pubMagicMetadata: {
                ...updatedPublicMagicMetadata,
                version: updatedPublicMagicMetadata.version + 1,
            },
        }),
    );
};
