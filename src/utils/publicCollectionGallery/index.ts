import { createContext } from 'react';
import { PublicCollectionGalleryContextType } from 'types/publicCollection';

export const defaultPublicCollectionGalleryContext: PublicCollectionGalleryContextType =
    {
        token: null,
        passwordToken: null,
        accessedThroughSharedURL: false,
        openReportForm: () => null,
        photoListHeader: null,
        photoListFooter: null,
    };

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>(
        defaultPublicCollectionGalleryContext
    );
