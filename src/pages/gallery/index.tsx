import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    File,
    getLocalFiles,
    deleteFiles,
    syncFiles,
} from 'services/fileService';
import styled from 'styled-components';
import LoadingBar from 'react-top-loading-bar';
import Collections from './components/Collections';
import Upload from './components/Upload';
import {
    Collection,
    syncCollections,
    CollectionAndItsLatestFile,
    getCollectionsAndTheirLatestFile,
    getFavItemIds,
    getLocalCollections,
    getNonEmptyCollections,
} from 'services/collectionService';
import constants from 'utils/strings/constants';
import { Alert } from 'react-bootstrap';
import billingService from 'services/billingService';
import PlanSelector from './components/PlanSelector';
import { checkSubscriptionPurchase } from 'utils/billingUtil';

import FullScreenDropZone from 'components/FullScreenDropZone';
import Sidebar from 'components/Sidebar';
import UploadButton from './components/UploadButton';
import { checkConnectivity } from 'utils/common';
import {
    isFirstLogin,
    justSignedUp,
    setIsFirstLogin,
    setJustSignedUp,
} from 'utils/storage';
import { logoutUser } from 'services/userService';
import AlertBanner from './components/AlertBanner';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
import { useDropzone } from 'react-dropzone';
import EnteSpinner from 'components/EnteSpinner';
import CollectionNamer, {
    CollectionNamerAttributes,
} from './components/CollectionNamer';
import CollectionSelector, {
    CollectionSelectorAttributes,
} from './components/CollectionSelector';
import { LoadingOverlay } from 'components/LoadingOverlay';
import PhotoFrame from 'components/PhotoFrame';
import { getSelectedFileIds } from 'utils/file';
import { addFilesToCollection } from 'utils/collection';
import SelectedFileOptions from './components/SelectedFileOptions';

export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    OTHERS,
}

export const DeadCenter = styled.div`
    flex: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    text-align: center;
    flex-direction: column;
`;

export type selectedState = {
    [k: number]: boolean;
    count: number;
};

export default function Gallery() {
    const router = useRouter();
    const [collections, setCollections] = useState<Collection[]>([]);
    const [
        collectionsAndTheirLatestFile,
        setCollectionsAndTheirLatestFile,
    ] = useState<CollectionAndItsLatestFile[]>([]);
    const [files, setFiles] = useState<File[]>(null);
    const [favItemIds, setFavItemIds] = useState<Set<number>>();
    const [bannerMessage, setBannerMessage] = useState<string>(null);
    const [sinceTime, setSinceTime] = useState(0);
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [selected, setSelected] = useState<selectedState>({ count: 0 });
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [dialogView, setDialogView] = useState(false);
    const [planModalView, setPlanModalView] = useState(false);
    const [loading, setLoading] = useState(false);
    const [
        collectionSelectorAttributes,
        setCollectionSelectorAttributes,
    ] = useState<CollectionSelectorAttributes>(null);
    const [collectionSelectorView, setCollectionSelectorView] = useState(false);

    const [
        collectionNamerAttributes,
        setCollectionNamerAttributes,
    ] = useState<CollectionNamerAttributes>(null);
    const [collectionNamerView, setCollectionNamerView] = useState(false);
    const {
        getRootProps,
        getInputProps,
        open: openFileUploader,
        acceptedFiles,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        accept: 'image/*, video/*, application/json, ',
    });

    const loadingBar = useRef(null);
    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push('/');
            return;
        }
        const main = async () => {
            setIsFirstLoad(isFirstLogin());
            if (justSignedUp()) {
                setPlanModalView(true);
            }
            setIsFirstLogin(false);
            const files = await getLocalFiles();
            const collections = await getLocalCollections();
            const nonEmptyCollections = getNonEmptyCollections(
                collections,
                files
            );
            const collectionsAndTheirLatestFile = await getCollectionsAndTheirLatestFile(
                nonEmptyCollections,
                files
            );
            setFiles(files);
            setCollections(nonEmptyCollections);
            setCollectionsAndTheirLatestFile(collectionsAndTheirLatestFile);
            const favItemIds = await getFavItemIds(files);
            setFavItemIds(favItemIds);
            await checkSubscriptionPurchase(setDialogMessage, router);
            await syncWithRemote();
            setIsFirstLoad(false);
            setJustSignedUp(false);
        };
        main();
    }, []);

    useEffect(() => setDialogView(true), [dialogMessage]);
    useEffect(() => setCollectionSelectorView(true), [
        collectionSelectorAttributes,
    ]);
    useEffect(() => setCollectionNamerView(true), [collectionNamerAttributes]);

    const syncWithRemote = async () => {
        try {
            checkConnectivity();
            loadingBar.current?.continuousStart();
            await billingService.updatePlans();
            await billingService.syncSubscription();
            const collections = await syncCollections();
            const { files, isUpdated } = await syncFiles(collections);
            const nonEmptyCollections = getNonEmptyCollections(
                collections,
                files
            );
            const collectionAndItsLatestFile = await getCollectionsAndTheirLatestFile(
                nonEmptyCollections,
                files
            );
            const favItemIds = await getFavItemIds(files);
            setCollections(nonEmptyCollections);
            if (isUpdated) {
                setFiles(files);
            }
            setCollectionsAndTheirLatestFile(collectionAndItsLatestFile);
            setFavItemIds(favItemIds);
            setSinceTime(new Date().getTime());
        } catch (e) {
            setBannerMessage(e.message);
            if (e.message === constants.SESSION_EXPIRED_MESSAGE) {
                setDialogMessage({
                    title: constants.SESSION_EXPIRED,
                    content: constants.SESSION_EXPIRED_MESSAGE,
                    staticBackdrop: true,
                    proceed: {
                        text: constants.LOGIN,
                        action: logoutUser,
                        variant: 'primary',
                    },
                });
            }
        } finally {
            loadingBar.current?.complete();
        }
    };

    const clearSelection = function () {
        setSelected({ count: 0 });
    };

    const selectCollection = (id?: number) => {
        const href = `/gallery?collection=${id || ''}`;
        router.push(href, undefined, { shallow: true });
    };

    if (!files) {
        return <div />;
    }
    const addToCollectionHelper = addFilesToCollection.bind(
        null,
        setCollectionSelectorView,
        selected,
        files,
        clearSelection,
        syncWithRemote,
        selectCollection
    );

    const showCreateCollectionModal = () =>
        setCollectionNamerAttributes({
            title: constants.CREATE_COLLECTION,
            buttonText: constants.CREATE,
            autoFilledName: '',
            callback: (collectionName) =>
                addToCollectionHelper(collectionName, null),
        });

    const deleteFileHelper = () =>
        deleteFiles(
            getSelectedFileIds(selected),
            clearSelection,
            syncWithRemote
        );
    return (
        <FullScreenDropZone
            getRootProps={getRootProps}
            getInputProps={getInputProps}
            showCollectionSelector={setCollectionSelectorView.bind(null, true)}
        >
            {loading && (
                <LoadingOverlay>
                    <EnteSpinner />
                </LoadingOverlay>
            )}
            <LoadingBar color="#2dc262" ref={loadingBar} />
            {isFirstLoad && (
                <div className="text-center">
                    <Alert variant="success">
                        {constants.INITIAL_LOAD_DELAY_WARNING}
                    </Alert>
                </div>
            )}
            <PlanSelector
                modalView={planModalView}
                closeModal={() => setPlanModalView(false)}
                setDialogMessage={setDialogMessage}
                setLoading={setLoading}
            />
            <AlertBanner bannerMessage={bannerMessage} />
            <MessageDialog
                show={dialogView}
                onHide={() => setDialogView(false)}
                attributes={dialogMessage}
            />
            <Collections
                collections={collections}
                selected={Number(router.query.collection)}
                selectCollection={selectCollection}
                syncWithRemote={syncWithRemote}
                setDialogMessage={setDialogMessage}
                setCollectionNamerAttributes={setCollectionNamerAttributes}
            />
            <CollectionNamer
                show={collectionNamerView}
                onHide={setCollectionNamerView.bind(null, false)}
                attributes={collectionNamerAttributes}
            />
            <CollectionSelector
                show={collectionSelectorView}
                onHide={setCollectionSelectorView.bind(null, false)}
                collectionsAndTheirLatestFile={collectionsAndTheirLatestFile}
                directlyShowNextModal={
                    collectionsAndTheirLatestFile?.length === 0
                }
                attributes={collectionSelectorAttributes}
            />
            <Upload
                syncWithRemote={syncWithRemote}
                setBannerMessage={setBannerMessage}
                acceptedFiles={acceptedFiles}
                existingFiles={files}
                setCollectionSelectorAttributes={
                    setCollectionSelectorAttributes
                }
                closeCollectionSelector={setCollectionSelectorView.bind(
                    null,
                    false
                )}
                setLoading={setLoading}
                setCollectionNamerAttributes={setCollectionNamerAttributes}
            />
            <Sidebar
                files={files}
                collections={collections}
                setDialogMessage={setDialogMessage}
                setPlanModalView={setPlanModalView}
            />
            <UploadButton openFileUploader={openFileUploader} />
            <PhotoFrame
                files={files}
                setFiles={setFiles}
                syncWithRemote={syncWithRemote}
                favItemIds={favItemIds}
                sinceTime={sinceTime}
                setSelected={setSelected}
                selected={selected}
                isFirstLoad={isFirstLoad}
                openFileUploader={openFileUploader}
                loadingBar={loadingBar}
            />
            {files.length < 30 && (
                <Alert
                    variant="success"
                    style={{
                        position: 'fixed',
                        bottom: '1%',
                        width: '100%',
                        textAlign: 'center',
                        marginBottom: '0px',
                    }}
                >
                    {constants.INSTALL_MOBILE_APP()}
                </Alert>
            )}
            {selected.count > 0 && (
                <SelectedFileOptions
                    addToCollectionHelper={addToCollectionHelper}
                    showCreateCollectionModal={showCreateCollectionModal}
                    setDialogMessage={setDialogMessage}
                    setCollectionSelectorAttributes={
                        setCollectionSelectorAttributes
                    }
                    deleteFileHelper={deleteFileHelper}
                />
            )}
        </FullScreenDropZone>
    );
}
