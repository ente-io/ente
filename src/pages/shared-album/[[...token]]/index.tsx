import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, { useContext, useEffect, useRef, useState } from 'react';
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
import { CollectionInfo } from 'components/pages/sharedAlbum/CollectionInfo';
import ReportAbuse from 'components/pages/sharedAlbum/ReportAbuse';
import { AbuseReportForm } from 'components/pages/sharedAlbum/AbuseReportForm';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
import GoToEnte from 'components/pages/sharedAlbum/GoToEnte';
import {
    defaultPublicCollectionGalleryContext,
    PublicCollectionGalleryContext,
} from 'utils/publicCollectionGallery';
import { useRouter } from 'next/router';

export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const appContext = useContext(AppContext);
    const [abuseReportFormView, setAbuseReportFormView] = useState(false);
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);

    const showReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);

    const openMessageDialog = () => setMessageDialogView(true);
    const closeMessageDialog = () => setMessageDialogView(false);
    const router = useRouter();
    useEffect(() => {
        const main = async () => {
            const eToken = (router.query.token?.[0] ?? '') as string;
            const eCollectionKey = decodeURIComponent(
                window.location.hash.slice(1)
            );
            if (!eToken || !eCollectionKey) {
                return;
            }
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

    useEffect(openMessageDialog, [dialogMessage]);

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
                setDialogMessage,
            }}>
            <GoToEnte />

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
                url={url.current}
            />
            <MessageDialog
                size="lg"
                show={messageDialogView}
                onHide={closeMessageDialog}
                attributes={dialogMessage}
            />
        </PublicCollectionGalleryContext.Provider>
    );
}
