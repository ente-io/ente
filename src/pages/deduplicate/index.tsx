import EnteSpinner from 'components/EnteSpinner';
import LeftArrow from 'components/icons/LeftArrow';
import { LoadingOverlay } from 'components/LoadingOverlay';
import MessageDialog, { MessageAttributes } from 'components/MessageDialog';
import SelectedDuplicatesOptions from 'components/pages/deduplicate/SelectedDuplicatesOptions';
import AlertBanner from 'components/pages/gallery/AlertBanner';
import PhotoFrame from 'components/PhotoFrame';
import ToastNotification from 'components/ToastNotification';
import { ALL_SECTION } from 'constants/collection';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import { defaultGalleryContext, GalleryContext } from 'pages/gallery';
import { AppContext } from 'pages/_app';
import React, { useContext, useEffect, useRef, useState } from 'react';
import LoadingBar from 'react-top-loading-bar';
import { syncCollections } from 'services/collectionService';
import deduplicationService from 'services/deduplicationService';
import { getLocalFiles, syncFiles, trashFiles } from 'services/fileService';
import { getLocalTrash, getTrashedFiles } from 'services/trashService';
import { isTokenValid, logoutUser } from 'services/userService';
import { EnteFile } from 'types/file';
import { NotificationAttributes, SelectedState } from 'types/gallery';
import { checkConnectivity } from 'utils/common';
import { CustomError, ServerErrorCodes } from 'utils/error';
import { getSelectedFiles, mergeMetadata, sortFiles } from 'utils/file';
import { isFirstLogin, setIsFirstLogin, setJustSignedUp } from 'utils/storage';
import { clearKeys, getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import constants from 'utils/strings/constants';

export default function Deduplicate() {
    const router = useRouter();
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [localFiles, setLocalFiles] = useState<EnteFile[]>(null);
    const [duplicateFiles, setDuplicateFiles] = useState<EnteFile[]>([]);
    const [bannerMessage, setBannerMessage] = useState<JSX.Element | string>(
        null
    );
    const [isFirstLoad, setIsFirstLoad] = useState(false);
    const [selected, setSelected] = useState<SelectedState>({
        count: 0,
        collectionID: 0,
    });
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const loadingBar = useRef(null);
    const isLoadingBarRunning = useRef(false);
    const syncInProgress = useRef(true);
    const resync = useRef(false);
    const appContext = useContext(AppContext);
    const [clubByTime, setClubByTime] = useState(false);
    const [fileSizeMap, setFileSizeMap] = useState(new Map<number, number>());

    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const closeMessageDialog = () => setMessageDialogView(false);

    const clearNotificationAttributes = () => setNotificationAttributes(null);

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            appContext.setRedirectURL(router.asPath);
            router.push(PAGES.ROOT);
            return;
        }
        const main = async () => {
            setIsFirstLoad(isFirstLogin());
            setIsFirstLogin(false);
            const localFiles = mergeMetadata(await getLocalFiles());
            const trash = await getLocalTrash();
            const trashedFile = getTrashedFiles(trash);
            setLocalFiles(sortFiles([...localFiles, ...trashedFile]));

            await syncWithRemote(true);
            setIsFirstLoad(false);
            setJustSignedUp(false);
        };
        main();
        appContext.showNavBar(true);
    }, []);

    useEffect(() => setMessageDialogView(true), [dialogMessage]);

    const syncWithRemote = async (force = false, silent = false) => {
        if (syncInProgress.current && !force) {
            resync.current = true;
            return;
        }
        syncInProgress.current = true;
        try {
            checkConnectivity();
            if (!(await isTokenValid())) {
                throw new Error(ServerErrorCodes.SESSION_EXPIRED);
            }
            !silent && startLoading();

            const collections = await syncCollections();
            await syncFiles(collections, setLocalFiles);

            let duplicates = await deduplicationService.getDuplicateFiles();
            if (clubByTime) {
                duplicates = await deduplicationService.clubDuplicatesByTime(
                    duplicates
                );
            }

            const currFileSizeMap = new Map<number, number>();

            let allDuplicateFiles: EnteFile[] = [];
            let toSelectFileIDs: number[] = [];
            let count = 0;

            for (const dupe of duplicates) {
                allDuplicateFiles = allDuplicateFiles.concat(dupe.files);
                // select all except first file
                toSelectFileIDs = toSelectFileIDs.concat(
                    dupe.files.slice(1).map((f) => f.id)
                );
                count += dupe.files.length - 1;

                for (const file of dupe.files) {
                    currFileSizeMap.set(file.id, dupe.size);
                }
            }
            setDuplicateFiles(allDuplicateFiles);
            setFileSizeMap(currFileSizeMap);

            const selectedFiles = {
                count: count,
                collectionID: 0,
            };

            for (const fileID of toSelectFileIDs) {
                selectedFiles[fileID] = true;
            }
            setSelected(selectedFiles);
        } catch (e) {
            switch (e.message) {
                case ServerErrorCodes.SESSION_EXPIRED:
                    setBannerMessage(constants.SESSION_EXPIRED_MESSAGE);
                    setDialogMessage({
                        title: constants.SESSION_EXPIRED,
                        content: constants.SESSION_EXPIRED_MESSAGE,
                        staticBackdrop: true,
                        nonClosable: true,
                        proceed: {
                            text: constants.LOGIN,
                            action: logoutUser,
                            variant: 'success',
                        },
                    });
                    break;
                case CustomError.KEY_MISSING:
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                    break;
            }
        } finally {
            !silent && finishLoading();
        }
        syncInProgress.current = false;
        if (resync.current) {
            resync.current = false;
            syncWithRemote();
        }
    };

    useEffect(() => {
        startLoading();
        const sync = async () => {
            await syncWithRemote();
        };
        sync();
        finishLoading();
    }, [clubByTime]);

    const clearSelection = function () {
        setSelected({ count: 0, collectionID: 0 });
    };

    const startLoading = () => {
        !isLoadingBarRunning.current && loadingBar.current?.continuousStart();
        isLoadingBarRunning.current = true;
    };
    const finishLoading = () => {
        isLoadingBarRunning.current && loadingBar.current?.complete();
        isLoadingBarRunning.current = false;
    };

    if (!duplicateFiles) {
        return <div />;
    }

    const deleteFileHelper = async () => {
        startLoading();
        try {
            const selectedFiles = getSelectedFiles(selected, duplicateFiles);
            await trashFiles(selectedFiles);
            clearSelection();
        } catch (e) {
            switch (e.status?.toString()) {
                case ServerErrorCodes.FORBIDDEN:
                    setDialogMessage({
                        title: constants.ERROR,
                        staticBackdrop: true,
                        close: { variant: 'danger' },
                        content: constants.NOT_FILE_OWNER,
                    });
            }
            setDialogMessage({
                title: constants.ERROR,
                staticBackdrop: true,
                close: { variant: 'danger' },
                content: constants.UNKNOWN_ERROR,
            });
        } finally {
            await syncWithRemote(false, true);
            finishLoading();
        }
    };

    return (
        <GalleryContext.Provider
            value={{
                ...defaultGalleryContext,
                closeMessageDialog,
                syncWithRemote,
                setDialogMessage,
                startLoading,
                finishLoading,
                setNotificationAttributes,
                setBlockingLoad,
            }}>
            {blockingLoad && (
                <LoadingOverlay>
                    <EnteSpinner />
                </LoadingOverlay>
            )}

            <LoadingBar color="#51cd7c" ref={loadingBar} />
            <AlertBanner bannerMessage={bannerMessage} />
            <ToastNotification
                attributes={notificationAttributes}
                clearAttributes={clearNotificationAttributes}
            />
            <MessageDialog
                size="lg"
                show={messageDialogView}
                onHide={closeMessageDialog}
                attributes={dialogMessage}
            />
            {duplicateFiles.length > 0 ? (
                <PhotoFrame
                    files={duplicateFiles}
                    setFiles={setDuplicateFiles}
                    syncWithRemote={syncWithRemote}
                    favItemIds={new Set()}
                    setSelected={setSelected}
                    selected={selected}
                    isFirstLoad={isFirstLoad}
                    isInSearchMode={false}
                    deleted={[]}
                    activeCollection={ALL_SECTION}
                    isSharedCollection={false}
                    enableDownload={true}
                    deduplicating={{
                        clubByTime: clubByTime,
                        fileSizeMap: fileSizeMap,
                    }}
                />
            ) : (
                <b
                    style={{
                        fontSize: '2em',
                        textAlign: 'center',
                        marginTop: '20%',
                    }}>
                    {constants.NO_DUPLICATES_FOUND}
                </b>
            )}

            {selected.count > 0 ? (
                <SelectedDuplicatesOptions
                    setDialogMessage={setDialogMessage}
                    deleteFileHelper={deleteFileHelper}
                    count={selected.count}
                    clearSelection={clearSelection}
                    clubByTime={clubByTime}
                    setClubByTime={setClubByTime}
                />
            ) : (
                <div
                    style={{
                        position: 'absolute',
                        top: '1em',
                        left: '1em',
                        zIndex: 10,
                    }}
                    onClick={() => {
                        router.push(PAGES.GALLERY);
                    }}>
                    <LeftArrow />
                </div>
            )}
        </GalleryContext.Provider>
    );
}
