import { createContext } from 'react';
import { PublicCollectionGalleryContextType } from 'types/publicCollection';

export const defaultPublicCollectionGalleryContext: PublicCollectionGalleryContextType =
    {
        token: null,
        accessedThroughSharedURL: false,
        setDialogMessage: () => null,
    };

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>(
        defaultPublicCollectionGalleryContext
    );
