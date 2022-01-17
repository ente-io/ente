import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, {
    createContext,
    useContext,
    useEffect,
    useRef,
    useState,
} from 'react';
import { SharedAlbumContextType } from 'types/publicCollection';
import {
    getLocalPublicCollection,
    getLocalPublicFiles,
    getPublicCollection,
    syncPublicFiles,
} from 'services/publicCollectionService';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { mergeMetadata, sortFiles } from 'utils/file';
import { AppContext } from 'pages/_app';
import OpenInEnte from 'components/pages/sharedAlbum/OpenInEnte';
import { CollectionInfo } from 'components/pages/sharedAlbum/CollectionInfo';

export const defaultSharedAlbumContext: SharedAlbumContextType = {
    token: null,
    accessedThroughSharedURL: false,
};

export const SharedAlbumContext = createContext<SharedAlbumContextType>(
    defaultSharedAlbumContext
);

export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const appContext = useContext(AppContext);

    useEffect(() => {
        const main = async () => {
            const urlParams = new URLSearchParams(window.location.search);
            const eToken = urlParams.get('accessToken');
            const eCollectionKey = decodeURIComponent(
                urlParams.get('collectionKey')
            );
            token.current = eToken;
            collectionKey.current = eCollectionKey;
            const localCollection = await getLocalPublicCollection(
                eCollectionKey
            );
            if (localCollection) {
                setPublicCollection(localCollection);
                const localPublicFiles = sortFiles(
                    mergeMetadata(
                        await getLocalPublicFiles(`${localCollection.id}`)
                    )
                );
                setPublicFiles(localPublicFiles);
                syncWithRemote(localCollection);
            } else {
                syncWithRemote();
            }
            appContext.showNavBar(true);
        };
        main();
    }, []);

    const syncWithRemote = async (collection?: Collection) => {
        if (!collection) {
            collection = await getPublicCollection(
                token.current,
                collectionKey.current
            );
        }
        await syncPublicFiles(token.current, collection, setPublicFiles);
    };

    if (!publicFiles) {
        return <div />;
    }
    return (
        <SharedAlbumContext.Provider
            value={{
                ...defaultSharedAlbumContext,
                token: token.current,
                accessedThroughSharedURL: true,
            }}>
            <OpenInEnte redirect={() => null} />

            <CollectionInfo collection={publicCollection} />

            <PhotoFrame
                files={publicFiles}
                setFiles={setPublicFiles}
                syncWithRemote={syncWithRemote}
                favItemIds={null}
                setSelected={() => null}
                selected={{ count: 0, collectionID: null }}
                isFirstLoad={false}
                openFileUploader={() => null}
                loadingBar={null}
                isInSearchMode={false}
                search={{}}
                setSearchStats={() => null}
                deleted={[]}
                activeCollection={ALL_SECTION}
                isSharedCollection
            />
        </SharedAlbumContext.Provider>
    );
}
