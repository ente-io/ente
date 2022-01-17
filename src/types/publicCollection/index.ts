import { EnteFile } from 'types/file';

export interface PublicCollectionGalleryContextType {
    token: string;
    accessedThroughSharedURL: boolean;
}

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}
