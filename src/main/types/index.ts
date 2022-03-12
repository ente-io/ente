export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    type: {
        mimeType: string;
        ext: string;
    };
    createReadStream: () => Promise<ReadableStream<Uint8Array>>;
    toBlob: () => Promise<Blob>;
    toUInt8Array: () => Promise<Uint8Array>;
}

export interface FileWithCollection {
    localID: number;
    collection: Collection;
    collectionID: number;
    file: ElectronFile;
}

export interface StoreFileWithCollection {
    localID: number;
    collection: Collection;
    collectionID: number;
    filePath: string;
}

export interface Collection {
    id: number;
    owner: User;
    key?: string;
    name?: string;
    encryptedName?: string;
    nameDecryptionNonce?: string;
    type: CollectionType;
    attributes: collectionAttributes;
    sharees: User[];
    updationTime: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
    isSharedCollection?: boolean;
    publicURLs?: PublicURL[];
}

interface User {
    id: number;
    name: string;
    email: string;
    token: string;
    encryptedToken: string;
    isTwoFactorEnabled: boolean;
    twoFactorSessionID: string;
}

interface PublicURL {
    url: string;
    deviceLimit: number;
    validTill: number;
    enableDownload: boolean;
    passwordEnabled: boolean;
    nonce: string;
    opsLimit: number;
    memLimit: number;
}

enum CollectionType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
}

interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string;
}
