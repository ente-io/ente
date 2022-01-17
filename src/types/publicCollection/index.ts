import { EnteFile } from 'types/file';

export interface SharedAlbumContextType {
    token: string;
    accessedThroughSharedURL: boolean;
}

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}
