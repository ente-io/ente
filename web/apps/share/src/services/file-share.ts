import bs58 from "bs58";
import {
    decryptBoxBytes,
    decryptMetadataJSON,
    decryptStreamBytes,
    fromHex,
    toB64,
} from "ente-base/crypto";
import { apiOrigin } from "ente-base/origins";
import type {
    DecryptedFileInfo,
    FileLinkInfo,
    FileMetadata,
    LockerInfo,
} from "../types/file-share";

/**
 * Extract file key from URL hash (similar to extractCollectionKeyFromShareURL)
 */
export const extractFileKeyFromURL = async (
    url: URL,
): Promise<string | null> => {
    const hashValue = url.hash.slice(1); // Remove '#' prefix
    if (!hashValue) return null;

    try {
        let decodedKey: string;
        // Support both base58 and hex encoding
        if (hashValue.length < 50) {
            // Base58 encoded - convert to base64
            const decoded = bs58.decode(hashValue);
            decodedKey = await toB64(decoded);
        } else {
            // Hex encoded - convert to base64
            decodedKey = await fromHex(hashValue);
        }
        return decodedKey;
    } catch {
        return null;
    }
};

/**
 * Fetch file info from the server
 */
export const fetchFileInfo = async (
    accessToken: string,
): Promise<FileLinkInfo> => {
    const url = `${await apiOrigin()}/file-link/info`;

    const response = await fetch(url, {
        headers: { "X-Auth-Access-Token": accessToken },
    });

    if (!response.ok) {
        throw new Error(`Failed to fetch file`);
    }

    const data = (await response.json()) as FileLinkInfo;
    return data;
};

/**
 * Decrypt file key from encrypted key and nonce
 */
const decryptFileKey = async (
    encryptedKey: string,
    keyDecryptionNonce: string,
    linkKey: string,
): Promise<string> => {
    try {
        const decryptedKeyBytes = await decryptBoxBytes(
            { encryptedData: encryptedKey, nonce: keyDecryptionNonce },
            linkKey,
        );
        return await toB64(decryptedKeyBytes);
    } catch {
        // If decryption fails, assume the link key IS the file key
        return linkKey;
    }
};

/**
 * Decrypt file metadata
 */
const decryptMetadata = async (
    encryptedData: string,
    decryptionHeader: string,
    fileKey: string,
): Promise<FileMetadata> => {
    try {
        const decryptedMetadata = await decryptMetadataJSON(
            { encryptedData, decryptionHeader },
            fileKey,
        );
        return decryptedMetadata as FileMetadata;
    } catch {
        return {};
    }
};

/**
 * Decrypt pubMagicMetadata
 */
const decryptPubMagicMetadata = async (
    data: string,
    header: string,
    fileKey: string,
): Promise<{ info?: string | LockerInfo } | null> => {
    try {
        const decryptedPubMagicMetadata = await decryptMetadataJSON(
            { encryptedData: data, decryptionHeader: header },
            fileKey,
        );
        return decryptedPubMagicMetadata as { info?: string | LockerInfo };
    } catch {
        return null;
    }
};

/**
 * Parse locker info from pubMagicMetadata
 */
const parseLockerInfo = (
    rawInfo: string | LockerInfo | undefined,
): LockerInfo | undefined => {
    if (!rawInfo) return undefined;

    if (typeof rawInfo === "string") {
        try {
            return JSON.parse(rawInfo) as LockerInfo;
        } catch {
            return undefined;
        }
    }

    return rawInfo;
};

/**
 * Extract file information from metadata and fallback sources
 */
const extractFileInfo = (
    metadata: FileMetadata,
    file: FileLinkInfo["file"],
    infoObject: LockerInfo | undefined,
): { fileName: string; fileSize: number; uploadedTime: number } => {
    const fileName =
        metadata.fileName || metadata.title || metadata.name || "Unknown file";

    const pubMagicFileSize = infoObject?.data?.size;
    const fileSizeFromInfo = file?.info?.fileSize || 0;

    const fileSize =
        pubMagicFileSize ||
        fileSizeFromInfo ||
        metadata.fileSize ||
        metadata.size ||
        file?.file?.size ||
        0;

    const metadataUploadTime =
        metadata.uploadedTime ||
        metadata.createdAt ||
        metadata.modificationTime;

    const uploadedTime = metadataUploadTime || file?.updationTime || 0;

    return { fileName, fileSize, uploadedTime };
};

/**
 * Decrypt file info
 */
export const decryptFileInfo = async (
    fileLinkInfo: FileLinkInfo,
    linkKey: string,
): Promise<DecryptedFileInfo> => {
    try {
        const file = fileLinkInfo.file;
        const ownerName = fileLinkInfo.ownerName;

        if (!file) {
            throw new Error("No file object in response");
        }

        // Decrypt the file key if it exists
        let fileKey = linkKey; // Default to link key
        if (file.encryptedKey && file.keyDecryptionNonce) {
            fileKey = await decryptFileKey(
                file.encryptedKey,
                file.keyDecryptionNonce,
                linkKey,
            );
        }

        const fileId = file.id || 0;
        const fileDecryptionHeader = file.file?.decryptionHeader;

        // Extract nested encrypted metadata and decryption header
        const encryptedMetadata =
            file.metadata?.encryptedData || file.encryptedMetadata;
        const metadataDecryptionHeader =
            file.metadata?.decryptionHeader || file.metadataDecryptionHeader;

        // Check if we have the necessary fields for decryption
        if (!encryptedMetadata || !metadataDecryptionHeader) {
            return {
                id: fileId,
                fileName: "Unknown file",
                fileSize: file.info?.fileSize || file.file?.size || 0,
                uploadedTime: file.updationTime || 0,
                ownerName,
                fileDecryptionHeader,
                fileNonce: undefined,
                fileKey,
            };
        }

        // Decrypt metadata
        const metadata = await decryptMetadata(
            encryptedMetadata,
            metadataDecryptionHeader,
            fileKey,
        );

        // Try to decrypt pubMagicMetadata if it exists
        let pubMagicMetadata: { info?: string | LockerInfo } | null = null;
        if (file.pubMagicMetadata?.data && file.pubMagicMetadata.header) {
            pubMagicMetadata = await decryptPubMagicMetadata(
                file.pubMagicMetadata.data,
                file.pubMagicMetadata.header,
                fileKey,
            );
        }

        // Parse locker info
        const infoObject = parseLockerInfo(pubMagicMetadata?.info);
        const lockerType = infoObject?.type;

        // Extract file info
        const { fileName, fileSize, uploadedTime } = extractFileInfo(
            metadata,
            file,
            infoObject,
        );

        return {
            id: fileId,
            fileName,
            fileSize,
            uploadedTime,
            ownerName,
            fileDecryptionHeader,
            fileNonce: undefined,
            fileKey,
            lockerType,
            lockerInfoData: infoObject?.data,
        };
    } catch {
        // Return partial info if decryption fails
        if (!fileLinkInfo.file) {
            return {
                id: 0,
                fileName: "Error: No file data",
                fileSize: 0,
                uploadedTime: 0,
                ownerName: fileLinkInfo.ownerName,
                fileDecryptionHeader: undefined,
                fileNonce: undefined,
                fileKey: linkKey,
            };
        }

        const file = fileLinkInfo.file;
        return {
            id: file.id || 0,
            fileName: "Encrypted file",
            fileSize: file.info?.fileSize || file.file?.size || 0,
            uploadedTime: file.updationTime || 0,
            ownerName: fileLinkInfo.ownerName,
            fileDecryptionHeader: file.file?.decryptionHeader,
            fileNonce: undefined,
            fileKey: linkKey,
        };
    }
};

/**
 * Download and decrypt file
 */
export const downloadFile = async (
    accessToken: string,
    fileKey: string,
    fileName: string,
    fileDecryptionHeader?: string,
    fileNonce?: string,
): Promise<void> => {
    const url = `${await apiOrigin()}/file-link/file`;

    // Fetch the encrypted file from the server
    const response = await fetch(url, {
        headers: { "X-Auth-Access-Token": accessToken },
    });

    if (!response.ok) {
        throw new Error(`Failed to download file: ${response.statusText}`);
    }

    // Get the response stream
    const body = response.body;
    if (!body) {
        throw new Error("Response body is empty");
    }

    const encryptedData = new Uint8Array(await response.arrayBuffer());

    let decryptedData: Uint8Array;

    if (fileDecryptionHeader) {
        // Modern format: Decrypt the file using the decryption header
        decryptedData = await decryptStreamBytes(
            { encryptedData, decryptionHeader: fileDecryptionHeader },
            fileKey,
        );
    } else if (fileNonce) {
        // Legacy format: Use box decryption with nonce
        decryptedData = await decryptBoxBytes(
            { encryptedData: await toB64(encryptedData), nonce: fileNonce },
            fileKey,
        );
    } else {
        // No encryption information, return as is
        decryptedData = encryptedData;
    }

    // Create a blob from the decrypted data
    const blob = new Blob([new Uint8Array(decryptedData)]);

    // Create download link
    const blobUrl = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = blobUrl;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(blobUrl);
};

/**
 * Format file size to human readable format
 */
export const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 Bytes";

    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const k = 1024;
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    const size = bytes / Math.pow(k, i);

    return `${Math.round(size)} ${sizes[i]}`;
};
