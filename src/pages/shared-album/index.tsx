import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, {
    createContext,
    useContext,
    useEffect,
    useRef,
    useState,
} from 'react';
import { PublicCollectionGalleryContextType } from 'types/publicCollection';
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
import ReportAbuse from 'components/pages/sharedAlbum/ReportAbuse';
import { AbuseReportForm } from 'components/pages/sharedAlbum/AbuseReportForm';

export const defaultPublicCollectionGalleryContext: PublicCollectionGalleryContextType =
    {
        token: null,
        accessedThroughSharedURL: false,
    };

export const PublicCollectionGalleryContext =
    createContext<PublicCollectionGalleryContextType>(
        defaultPublicCollectionGalleryContext
    );

export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const appContext = useContext(AppContext);
    const [abuseReportFormView, setAbuseReportFormView] = useState(false);

    const showReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);
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
        <PublicCollectionGalleryContext.Provider
            value={{
                ...defaultPublicCollectionGalleryContext,
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
            <ReportAbuse onClick={showReportForm} />
            <AbuseReportForm
                show={abuseReportFormView}
                close={closeReportForm}
            />
        </PublicCollectionGalleryContext.Provider>
    );
}
