import bs58 from "bs58";
import {
    decryptBoxBytes,
    decryptMetadataJSON,
    decryptStreamBytes,
    deriveKey,
    fromHex,
    toB64,
} from "ente-base/crypto";
import { apiOrigin } from "ente-base/origins";
import type {
    DecryptedFileInfo,
    FileLinkInfo,
    FileMetadata,
    LinkKeyMaterial,
} from "../types/file-share";

/**
 * Extract file key from URL hash (similar to extractCollectionKeyFromShareURL)
 */
export const extractFileKeyFromURL = async (
    url: URL,
): Promise<LinkKeyMaterial | null> => {
    const hashValue = url.hash.slice(1).split("-")[0]; // Remove '#' prefix and take part before hyphen
    if (!hashValue) return null;

    try {
        const base62SecretPattern = /^[0-9A-Za-z]{12}$/;

        if (hashValue.length === 12 && base62SecretPattern.test(hashValue)) {
            return { type: "secret", passphrase: hashValue };
        }

        // Support both base58 and hex encoding for legacy links
        if (hashValue.length < 50) {
            // Base58 encoded - convert to base64
            const decoded = bs58.decode(hashValue);
            return { type: "direct", fileKey: await toB64(decoded) };
        }
        // Hex encoded - convert to base64
        return { type: "direct", fileKey: await fromHex(hashValue) };
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
 * Determine file type from filename
 */
const getFileType = (fileName: string): "image" | "video" | "other" => {
    const extension = fileName.split(".").pop()?.toLowerCase() || "";

    const imageExtensions = [
        "jpg",
        "jpeg",
        "png",
        "gif",
        "webp",
        "bmp",
        "svg",
        "heic",
        "heif",
        "ico",
        "tiff",
        "tif",
    ];
    const videoExtensions = [
        "mp4",
        "mov",
        "avi",
        "mkv",
        "webm",
        "wmv",
        "flv",
        "m4v",
        "3gp",
        "3g2",
        "ogv",
        "mpg",
        "mpeg",
    ];

    if (imageExtensions.includes(extension)) return "image";
    if (videoExtensions.includes(extension)) return "video";
    return "other";
};

/**
 * Extract file information from metadata and fallback sources
 */
const extractFileInfo = (
    metadata: FileMetadata,
    file: FileLinkInfo["file"],
): { fileName: string; fileSize: number; uploadedTime: number } => {
    const fileName =
        metadata.fileName ||
        metadata.title ||
        metadata.name ||
        "Unknown file";

    const fileSizeFromInfo = file?.info?.fileSize || 0;

    const fileSize =
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

const resolveFileKey = async (
    fileLinkInfo: FileLinkInfo,
    keyMaterial: LinkKeyMaterial,
): Promise<string> => {
    const file = fileLinkInfo.file;

    if (keyMaterial.type === "secret") {
        const linkMeta = fileLinkInfo.link;
        if (
            !linkMeta?.encryptedFileKey ||
            !linkMeta.encryptedFileKeyNonce ||
            !linkMeta.kdfNonce ||
            linkMeta.kdfMemLimit == null ||
            linkMeta.kdfOpsLimit == null
        ) {
            throw new Error("Missing link metadata for deriving file key");
        }

        const derivedKey = await deriveKey(
            keyMaterial.passphrase,
            linkMeta.kdfNonce,
            linkMeta.kdfOpsLimit,
            linkMeta.kdfMemLimit,
        );

        const decryptedKeyBytes = await decryptBoxBytes(
            {
                encryptedData: linkMeta.encryptedFileKey,
                nonce: linkMeta.encryptedFileKeyNonce,
            },
            derivedKey,
        );
        return await toB64(decryptedKeyBytes);
    }

    if (file?.encryptedKey && file.keyDecryptionNonce) {
        return await decryptFileKey(
            file.encryptedKey,
            file.keyDecryptionNonce,
            keyMaterial.fileKey,
        );
    }

    return keyMaterial.fileKey;
};

/**
 * Decrypt file info
 */
export const decryptFileInfo = async (
    fileLinkInfo: FileLinkInfo,
    keyMaterial: LinkKeyMaterial,
): Promise<DecryptedFileInfo> => {
    // enableDownload defaults to true if not specified
    const enableDownload = fileLinkInfo.link?.enableDownload ?? true;

    try {
        const file = fileLinkInfo.file;
        const ownerName = fileLinkInfo.ownerName;

        if (!file) {
            throw new Error("No file object in response");
        }

        const fileKey = await resolveFileKey(fileLinkInfo, keyMaterial);

        const fileId = file.id || 0;
        const fileDecryptionHeader = file.file?.decryptionHeader;
        const thumbnailDecryptionHeader = file.thumbnail?.decryptionHeader;

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
                thumbnailDecryptionHeader,
                fileNonce: undefined,
                fileKey,
                fileType: "other",
                enableDownload,
            };
        }

        // Decrypt metadata
        const metadata = await decryptMetadata(
            encryptedMetadata,
            metadataDecryptionHeader,
            fileKey,
        );

        // Extract file info
        const { fileName, fileSize, uploadedTime } = extractFileInfo(
            metadata,
            file,
        );

        return {
            id: fileId,
            fileName,
            fileSize,
            uploadedTime,
            ownerName,
            fileDecryptionHeader,
            thumbnailDecryptionHeader,
            fileNonce: undefined,
            fileKey,
            fileType: getFileType(fileName),
            enableDownload,
        };
    } catch {
        const fallbackKey =
            keyMaterial.type === "secret"
                ? keyMaterial.passphrase
                : keyMaterial.fileKey;
        // Return partial info if decryption fails
        if (!fileLinkInfo.file) {
            return {
                id: 0,
                fileName: "Error: No file data",
                fileSize: 0,
                uploadedTime: 0,
                ownerName: fileLinkInfo.ownerName,
                fileDecryptionHeader: undefined,
                thumbnailDecryptionHeader: undefined,
                fileNonce: undefined,
                fileKey: fallbackKey,
                fileType: "other",
                enableDownload,
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
            thumbnailDecryptionHeader: file.thumbnail?.decryptionHeader,
            fileNonce: undefined,
            fileKey: fallbackKey,
            fileType: "other",
            enableDownload,
        };
    }
};

/**
 * Download and decrypt thumbnail
 */
export const downloadThumbnail = async (
    accessToken: string,
    fileKey: string,
    thumbnailDecryptionHeader?: string,
): Promise<Blob | null> => {
    const url = `${await apiOrigin()}/file-link/thumbnail`;

    const response = await fetch(url, {
        headers: { "X-Auth-Access-Token": accessToken },
    });

    if (!response.ok) {
        return null;
    }

    const encryptedData = new Uint8Array(await response.arrayBuffer());

    if (thumbnailDecryptionHeader) {
        const decryptedData = await decryptStreamBytes(
            { encryptedData, decryptionHeader: thumbnailDecryptionHeader },
            fileKey,
        );
        return new Blob([decryptedData]);
    }

    return new Blob([encryptedData]);
};

/**
 * Get decrypted file as a blob URL for viewing
 */
export const getFileUrl = async (
    accessToken: string,
    fileKey: string,
    fileDecryptionHeader?: string,
    fileNonce?: string,
): Promise<string | null> => {
    const url = `${await apiOrigin()}/file-link/file`;

    const response = await fetch(url, {
        headers: { "X-Auth-Access-Token": accessToken },
    });

    if (!response.ok) {
        return null;
    }

    const encryptedData = new Uint8Array(await response.arrayBuffer());

    let decryptedData: Uint8Array;

    if (fileDecryptionHeader) {
        decryptedData = await decryptStreamBytes(
            { encryptedData, decryptionHeader: fileDecryptionHeader },
            fileKey,
        );
    } else if (fileNonce) {
        decryptedData = await decryptBoxBytes(
            { encryptedData: await toB64(encryptedData), nonce: fileNonce },
            fileKey,
        );
    } else {
        decryptedData = encryptedData;
    }

    const blob = new Blob([new Uint8Array(decryptedData)]);
    return URL.createObjectURL(blob);
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
