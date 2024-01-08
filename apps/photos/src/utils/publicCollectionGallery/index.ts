import { createContext } from 'react';
import { PublicCollectionGalleryContextType } from 'types/publicCollection';

const defaultPublicCollectionGalleryContext: PublicCollectionGalleryContextType =
    {
        token: null,
        passwordToken: null,
        referralCode: null,
        accessedThroughSharedURL: false,
        photoListHeader: null,
        photoListFooter: null,
    };

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>(
        defaultPublicCollectionGalleryContext
    );
