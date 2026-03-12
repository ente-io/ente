import { decryptBoxBytes } from "ente-base/crypto";
import { ensureOk, publicRequestHeaders } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import {
    decryptRemoteFile,
    RemoteEnteFile,
    type EnteFile,
} from "ente-media/file";
import { z } from "zod";
import { gunzip } from "../../photos/utils/gzip";

/**
 * Credentials needed to make public memory share related API requests.
 */
export interface PublicMemoryCredentials {
    /**
     * The access token for the public memory share.
     *
     * This is obtained from the "t" query parameter of the share URL.
     * It both identifies the share and authenticates the request.
     */
    accessToken: string;
}

/**
 * Return headers for public memory share API requests.
 */
export const authenticatedPublicMemoryRequestHeaders = ({
    accessToken,
}: PublicMemoryCredentials) => ({
    "X-Auth-Access-Token": accessToken,
    ...publicRequestHeaders(),
});

/**
 * Information about a public memory share fetched from remote.
 */
export interface PublicMemoryShareInfo {
    id: number;
    type: "share" | "lane";
    memoryHash?: string;
    metadataCipher: string;
    metadataNonce: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

const PublicMemoryShareInfoResponse = z.object({
    memoryShare: z.object({
        id: z.number(),
        type: z.enum(["share", "lane"]).optional().default("share"),
        memoryHash: z.string().optional(),
        metadataCipher: z.string().optional().default(""),
        metadataNonce: z.string().optional().default(""),
        encryptedKey: z.string(),
        keyDecryptionNonce: z.string(),
    }),
});

/**
 * Fetch information about a public memory share from remote.
 *
 * @param accessToken The access token from the memory share URL.
 */
export const getPublicMemoryInfo = async (
    accessToken: string,
): Promise<PublicMemoryShareInfo> => {
    const res = await fetch(await apiURL("/public-memory/info"), {
        headers: authenticatedPublicMemoryRequestHeaders({ accessToken }),
    });
    ensureOk(res);
    const { memoryShare } = PublicMemoryShareInfoResponse.parse(
        await res.json(),
    );
    return memoryShare;
};

/**
 * A file in a public memory share, with its key re-encrypted to the share key.
 */
const PublicMemoryShareFile = z.object({
    file: RemoteEnteFile,
    position: z.number(),
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
});

const PublicMemoryShareFilesResponse = z.object({
    files: PublicMemoryShareFile.array(),
});

export interface PublicMemoryFile {
    file: EnteFile;
    position: number;
}

export interface PublicMemoryShareFrameCrop {
    x: number;
    y: number;
    width: number;
    height: number;
}

export interface PublicMemoryShareFrame {
    fileID: number;
    position?: number;
    faceID?: string;
    faceBox?: PublicMemoryShareFrameCrop;
    crop?: PublicMemoryShareFrameCrop;
    creationTime?: number;
    year?: number;
}

export interface PublicMemoryShareMetadata {
    name: string;
    kind?: "share" | "lane";
    captionType?: "age" | "yearsAgo";
    personID?: string;
    personName?: string;
    birthDate?: string;
    frames: PublicMemoryShareFrame[];
}

const PublicMemoryShareFrameCropSchema = z.object({
    x: z.number(),
    y: z.number(),
    width: z.number(),
    height: z.number(),
});

const PublicMemoryShareFrameSchema = z.object({
    fileID: z.number(),
    position: z.number().optional(),
    faceID: z.string().optional(),
    faceBox: PublicMemoryShareFrameCropSchema.optional(),
    crop: PublicMemoryShareFrameCropSchema.optional(),
    creationTime: z.number().optional(),
    year: z.number().optional(),
});

const PublicMemoryShareMetadataBaseSchema = z.looseObject({
    name: z.string().optional(),
    kind: z.enum(["share", "lane"]).optional(),
    captionType: z.enum(["age", "yearsAgo"]).optional(),
    personID: z.string().optional(),
    personName: z.string().optional(),
    birthDate: z.string().optional(),
    frames: z.array(z.unknown()).optional(),
});

/**
 * Fetch the files in a public memory share, decrypt them using the provided
 * share key, and return them as {@link EnteFile}s.
 *
 * @param accessToken The access token from the memory share URL.
 * @param shareKey The base64 encoded per-share key (from the URL hash).
 */
export const getPublicMemoryFiles = async (
    accessToken: string,
    shareKey: string,
): Promise<PublicMemoryFile[]> => {
    const res = await fetch(await apiURL("/public-memory/files"), {
        headers: authenticatedPublicMemoryRequestHeaders({ accessToken }),
    });
    ensureOk(res);
    const { files } = PublicMemoryShareFilesResponse.parse(await res.json());

    const publicFiles: PublicMemoryFile[] = [];
    for (const { file, position, encryptedKey, keyDecryptionNonce } of files) {
        // The file's key is re-encrypted to the per-share key.
        // Override the file's encryptedKey/nonce with the share-level values
        // so that decryptRemoteFile can decrypt using the shareKey.
        const remoteFile = { ...file, encryptedKey, keyDecryptionNonce };
        const decrypted = await decryptRemoteFile(remoteFile, shareKey);
        publicFiles.push({ file: decrypted, position });
    }
    return publicFiles.sort((a, b) => a.position - b.position);
};

const decryptMemoryShareMetadataJSON = async (
    metadataCipher: string,
    metadataNonce: string,
    shareKey: string,
): Promise<string> => {
    const metadataBytes = await decryptBoxBytes(
        { encryptedData: metadataCipher, nonce: metadataNonce },
        shareKey,
    );
    let metadataJson: string;
    try {
        metadataJson = new TextDecoder().decode(metadataBytes);
        JSON.parse(metadataJson);
    } catch {
        metadataJson = await gunzip(metadataBytes);
    }
    return metadataJson;
};

/**
 * Decrypt the memory share's metadata.
 *
 * The metadata is a JSON object encrypted with the per-share key.
 * For lane shares, it can include per-frame crop data that the web app can use
 * directly for rendering without recomputing face placement.
 */
export const decryptMemoryShareMetadata = async (
    metadataCipher: string,
    metadataNonce: string,
    shareKey: string,
): Promise<PublicMemoryShareMetadata> => {
    const metadataJson = await decryptMemoryShareMetadataJSON(
        metadataCipher,
        metadataNonce,
        shareKey,
    );
    const metadata = PublicMemoryShareMetadataBaseSchema.parse(
        JSON.parse(metadataJson),
    );
    const frames = (metadata.frames ?? []).flatMap((frame) => {
        const parsed = PublicMemoryShareFrameSchema.safeParse(frame);
        return parsed.success ? [parsed.data] : [];
    });

    return {
        name: metadata.name ?? "",
        kind: metadata.kind,
        captionType: metadata.captionType,
        personID: metadata.personID,
        personName: metadata.personName,
        birthDate: metadata.birthDate,
        frames,
    };
};

/**
 * Decrypt the memory share's metadata and extract the name.
 */
export const decryptMemoryShareName = async (
    metadataCipher: string,
    metadataNonce: string,
    shareKey: string,
): Promise<string> => {
    const metadata = await decryptMemoryShareMetadata(
        metadataCipher,
        metadataNonce,
        shareKey,
    );
    return metadata.name;
};
