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
import { AbuseReportForm } from 'components/pages/sharedAlbum/AbuseReportForm';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
import {
    defaultPublicCollectionGalleryContext,
    PublicCollectionGalleryContext,
} from 'utils/publicCollectionGallery';
import { CustomError, parseSharingErrorCodes } from 'utils/error';
import Container from 'components/Container';
import constants from 'utils/strings/constants';
import EnteSpinner from 'components/EnteSpinner';
import LoadingBar from 'react-top-loading-bar';
import CryptoWorker from 'utils/crypto';
import { PAGES } from 'constants/pages';
import router from 'next/router';

export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>([]);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const appContext = useContext(AppContext);
    const [abuseReportFormView, setAbuseReportFormView] = useState(false);
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [loading, setLoading] = useState(true);
    const openReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);
    const loadingBar = useRef(null);
    const [isLoadingBarRunning, setIsLoadingBarRunning] = useState(false);

    const openMessageDialog = () => setMessageDialogView(true);
    const closeMessageDialog = () => setMessageDialogView(false);

    const startLoading = () => {
        !isLoadingBarRunning && loadingBar.current?.continuousStart();
        setIsLoadingBarRunning(true);
    };
    const finishLoading = () => {
        loadingBar.current?.complete();
        setIsLoadingBarRunning(false);
    };

    useEffect(() => {
        appContext.showNavBar(true);
        setLoading(false);
        const currentURL = new URL(window.location.href);
        if (currentURL.pathname !== PAGES.ROOT) {
            router.push(
                {
                    pathname: PAGES.SHARED_ALBUMS,
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    pathname: PAGES.ROOT,
                    search: currentURL.search,
                    hash: currentURL.hash,
                }
            );
        }
        const main = async () => {
            const worker = await new CryptoWorker();
            url.current = window.location.href;
            const currentURL = new URL(url.current);
            const t = currentURL.searchParams.get('t');
            const ck = currentURL.hash.slice(1);
            const dck = await worker.fromHex(ck);
            if (!t || !dck) {
                setLoading(false);
                return;
            }
            token.current = t;
            collectionKey.current = dck;
            url.current = window.location.href;
            const localCollection = await getLocalPublicCollection(
                collectionKey.current
            );
            if (localCollection) {
                setPublicCollection(localCollection);
                const localPublicFiles = sortFiles(
                    mergeMetadata(await getLocalPublicFiles(localCollection))
                );
                setPublicFiles(localPublicFiles);
            }
            syncWithRemote();
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
            const parsedError = parseSharingErrorCodes(e);
            if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                // share has been disabled
                // local cache should be cleared
                removePublicCollectionWithFiles(collectionKey.current);
                setPublicCollection(null);
                setPublicFiles([]);
            }
        } finally {
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
    if (!isLoadingBarRunning && !publicFiles) {
        return <Container>{constants.NOT_FOUND}</Container>;
    }
    return (
        <PublicCollectionGalleryContext.Provider
            value={{
                ...defaultPublicCollectionGalleryContext,
                token: token.current,
                accessedThroughSharedURL: true,
                setDialogMessage,
                openReportForm,
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
                isFirstLoad={true}
                openFileUploader={() => null}
                isInSearchMode={false}
                search={{}}
                setSearchStats={() => null}
                deleted={[]}
                activeCollection={ALL_SECTION}
                isSharedCollection
            />
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
