import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, { useContext, useEffect, useRef, useState } from 'react';
import {
    getLocalPublicCollection,
    getLocalPublicFiles,
    getPublicCollection,
    removePublicCollectionWithFiles,
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
import {
    defaultPublicCollectionGalleryContext,
    PublicCollectionGalleryContext,
} from 'utils/publicCollectionGallery';
import { CustomError } from 'utils/error';
import Container from 'components/Container';
import constants from 'utils/strings/constants';
import EnteSpinner from 'components/EnteSpinner';
import LoadingBar from 'react-top-loading-bar';
import CryptoWorker from 'utils/crypto';

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
    const [loading, setLoading] = useState(true);
    const showReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);
    const loadingBar = useRef(null);

    const openMessageDialog = () => setMessageDialogView(true);
    const closeMessageDialog = () => setMessageDialogView(false);

    const startLoading = () => loadingBar.current?.continuousStart();
    const finishLoading = () => loadingBar.current?.complete();

    useEffect(() => {
        const main = async () => {
            const worker = await new CryptoWorker();
            url.current = window.location.href;
            const urlS = new URL(url.current);
            const eToken = urlS.searchParams.get('t');
            const eCollectionKey = urlS.hash.slice(1);
            const decodedCollectionKey = await worker.fromHex(eCollectionKey);
            if (!eToken || !decodedCollectionKey) {
                setLoading(false);
                return;
            }
            token.current = eToken;
            collectionKey.current = decodedCollectionKey;
            url.current = window.location.href;
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
                setLoading(false);
            }
            syncWithRemote();
            appContext.showNavBar(true);
        };
        main();
    }, []);

    useEffect(openMessageDialog, [dialogMessage]);

    const syncWithRemote = async () => {
        try {
            startLoading();
            const collection = await getPublicCollection(
                token.current,
                collectionKey.current
            );
            setPublicCollection(collection);

            await syncPublicFiles(token.current, collection, setPublicFiles);
        } catch (e) {
            if (e.message === CustomError.TOKEN_EXPIRED) {
                // share has been disabled
                // local cache should be cleared
                removePublicCollectionWithFiles(collectionKey.current);
                setPublicCollection(null);
                setPublicFiles(null);
            }
        } finally {
            setLoading(false);
            finishLoading();
        }
    };
    if (loading) {
        return (
            <Container>
                <EnteSpinner>
                    <span className="sr-only">Loading...</span>
                </EnteSpinner>
            </Container>
        );
    }
    if (!publicFiles) {
        return <Container>{constants.NOT_FOUND}</Container>;
    }
    return (
        <PublicCollectionGalleryContext.Provider
            value={{
                ...defaultPublicCollectionGalleryContext,
                token: token.current,
                accessedThroughSharedURL: true,
                setDialogMessage,
            }}>
            <LoadingBar color="#51cd7c" ref={loadingBar} />
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
                loadingBar={loadingBar}
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
