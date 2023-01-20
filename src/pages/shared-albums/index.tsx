import { ALL_SECTION } from 'constants/collection';
import PhotoFrame from 'components/PhotoFrame';
import React, { useContext, useEffect, useRef, useState } from 'react';
import {
    getLocalPublicCollection,
    getLocalPublicCollectionPassword,
    getLocalPublicFiles,
    getPublicCollection,
    getPublicCollectionUID,
    removePublicCollectionWithFiles,
    removePublicFiles,
    savePublicCollectionPassword,
    syncPublicFiles,
    verifyPublicCollectionPassword,
} from 'services/publicCollectionService';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { mergeMetadata, sortFiles } from 'utils/file';
import { AppContext } from 'pages/_app';
import { AbuseReportForm } from 'components/pages/sharedAlbum/AbuseReportForm';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { CustomError, parseSharingErrorCodes } from 'utils/error';
import VerticallyCentered, { CenteredFlex } from 'components/Container';
import constants from 'utils/strings/constants';
import EnteSpinner from 'components/EnteSpinner';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { logError } from 'utils/sentry';
import SharedAlbumNavbar from 'components/pages/sharedAlbum/Navbar';
import { CollectionInfo } from 'components/Collections/CollectionInfo';
import { CollectionInfoBarWrapper } from 'components/Collections/styledComponents';
import { ITEM_TYPE, TimeStampListItem } from 'components/PhotoList';
import FormContainer from 'components/Form/FormContainer';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import Typography from '@mui/material/Typography';
import Uploader from 'components/Upload/Uploader';
import { LoadingOverlay } from 'components/LoadingOverlay';
import FullScreenDropZone from 'components/FullScreenDropZone';
import useFileInput from 'hooks/useFileInput';
import { useDropzone } from 'react-dropzone';
import UploadSelectorInputs from 'components/UploadSelectorInputs';
import { logoutUser } from 'services/userService';
import UploadButton from 'components/Upload/UploadButton';
import bs58 from 'bs58';
import AddPhotoAlternateOutlined from '@mui/icons-material/AddPhotoAlternateOutlined';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';

const Loader = () => (
    <VerticallyCentered>
        <EnteSpinner>
            <span className="sr-only">Loading...</span>
        </EnteSpinner>
    </VerticallyCentered>
);
export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    // passwordJWTToken refers to the jwt token which is used for album protected by password.
    const passwordJWTToken = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const [errorMessage, setErrorMessage] = useState<string>(null);
    const appContext = useContext(AppContext);
    const [abuseReportFormView, setAbuseReportFormView] = useState(false);
    const [loading, setLoading] = useState(true);
    const openReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);
    const router = useRouter();
    const [isPasswordProtected, setIsPasswordProtected] =
        useState<boolean>(false);
    const [photoListHeader, setPhotoListHeader] =
        useState<TimeStampListItem>(null);

    const [photoListFooter, setPhotoListFooter] =
        useState<TimeStampListItem>(null);

    const [uploadTypeSelectorView, setUploadTypeSelectorView] = useState(false);
    const [blockingLoad, setBlockingLoad] = useState(false);
    const [shouldDisableDropzone, setShouldDisableDropzone] = useState(false);

    const {
        getRootProps: getDragAndDropRootProps,
        getInputProps: getDragAndDropInputProps,
        acceptedFiles: dragAndDropFiles,
    } = useDropzone({
        noClick: true,
        noKeyboard: true,
        disabled: shouldDisableDropzone,
    });
    const {
        selectedFiles: webFileSelectorFiles,
        open: openFileSelector,
        getInputProps: getFileSelectorInputProps,
    } = useFileInput({
        directory: false,
    });
    const {
        selectedFiles: webFolderSelectorFiles,
        open: openFolderSelector,
        getInputProps: getFolderSelectorInputProps,
    } = useFileInput({
        directory: true,
    });

    const openUploader = () => {
        setUploadTypeSelectorView(true);
    };

    const closeUploadTypeSelectorView = () => {
        setUploadTypeSelectorView(false);
    };

    const showPublicLinkExpiredMessage = () =>
        appContext.setDialogMessage({
            title: constants.LINK_EXPIRED,
            content: constants.LINK_EXPIRED_MESSAGE,

            nonClosable: true,
            proceed: {
                text: constants.LOGIN,
                action: logoutUser,
                variant: 'accent',
            },
        });

    useEffect(() => {
        const currentURL = new URL(window.location.href);
        if (currentURL.pathname !== PAGES.ROOT) {
            router.replace(
                {
                    pathname: PAGES.SHARED_ALBUMS,
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    pathname: PAGES.ROOT,
                    search: currentURL.search,
                    hash: currentURL.hash,
                },
                {
                    shallow: true,
                }
            );
        }
        const main = async () => {
            try {
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();

                url.current = window.location.href;
                const currentURL = new URL(url.current);
                const t = currentURL.searchParams.get('t');
                const ck = currentURL.hash.slice(1);
                if (!t || !ck) {
                    return;
                }
                const dck =
                    ck.length < 50
                        ? await cryptoWorker.toB64(bs58.decode(ck))
                        : await cryptoWorker.fromHex(ck);
                token.current = t;
                collectionKey.current = dck;
                url.current = window.location.href;
                const localCollection = await getLocalPublicCollection(
                    collectionKey.current
                );
                if (localCollection) {
                    setPublicCollection(localCollection);
                    const isPasswordProtected =
                        localCollection?.publicURLs?.[0]?.passwordEnabled;
                    setIsPasswordProtected(isPasswordProtected);
                    const collectionUID = getPublicCollectionUID(token.current);
                    const localFiles = await getLocalPublicFiles(collectionUID);
                    const localPublicFiles = sortFiles(
                        mergeMetadata(localFiles)
                    );
                    setPublicFiles(localPublicFiles);
                    passwordJWTToken.current =
                        await getLocalPublicCollectionPassword(collectionUID);
                }
                await syncWithRemote();
            } finally {
                setLoading(false);
            }
        };
        main();
    }, []);

    useEffect(() => {
        publicCollection &&
            publicFiles &&
            setPhotoListHeader({
                item: (
                    <CollectionInfoBarWrapper>
                        <CollectionInfo
                            name={publicCollection.name}
                            fileCount={publicFiles.length}
                        />
                    </CollectionInfoBarWrapper>
                ),
                itemType: ITEM_TYPE.HEADER,
                height: 68,
            });
    }, [publicCollection, publicFiles]);

    useEffect(() => {
        if (publicCollection?.publicURLs?.[0]?.enableCollect) {
            setPhotoListFooter({
                item: (
                    <CenteredFlex sx={{ marginTop: '56px' }}>
                        <UploadButton
                            disableShrink
                            openUploader={openUploader}
                            text={constants.ADD_MORE_PHOTOS}
                            color="accent"
                            icon={<AddPhotoAlternateOutlined />}
                        />
                    </CenteredFlex>
                ),
                itemType: ITEM_TYPE.FOOTER,
                height: 104,
            });
        } else {
            setPhotoListFooter(null);
        }
    }, [publicCollection]);

    const syncWithRemote = async () => {
        const collectionUID = getPublicCollectionUID(token.current);
        try {
            appContext.startLoading();
            setLoading(true);
            const collection = await getPublicCollection(
                token.current,
                collectionKey.current
            );
            setPublicCollection(collection);
            const isPasswordProtected =
                collection?.publicURLs?.[0]?.passwordEnabled;
            setIsPasswordProtected(isPasswordProtected);
            setErrorMessage(null);

            // remove outdated password, sharer has disabled the password
            if (!isPasswordProtected && passwordJWTToken.current) {
                passwordJWTToken.current = null;
                savePublicCollectionPassword(collectionUID, null);
            }
            if (
                !isPasswordProtected ||
                (isPasswordProtected && passwordJWTToken.current)
            ) {
                try {
                    await syncPublicFiles(
                        token.current,
                        passwordJWTToken.current,
                        collection,
                        setPublicFiles
                    );
                } catch (e) {
                    const parsedError = parseSharingErrorCodes(e);
                    if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                        // passwordToken has expired, sharer has changed the password,
                        // so,clearing local cache token value to prompt user to re-enter password
                        passwordJWTToken.current = null;
                    }
                }
            }
            if (isPasswordProtected && !passwordJWTToken.current) {
                await removePublicFiles(collectionUID);
            }
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            if (
                parsedError.message === CustomError.TOKEN_EXPIRED ||
                parsedError.message === CustomError.TOO_MANY_REQUESTS
            ) {
                setErrorMessage(
                    parsedError.message === CustomError.TOO_MANY_REQUESTS
                        ? constants.LINK_TOO_MANY_REQUESTS
                        : constants.LINK_EXPIRED_MESSAGE
                );
                // share has been disabled
                // local cache should be cleared
                removePublicCollectionWithFiles(
                    collectionUID,
                    collectionKey.current
                );
                setPublicCollection(null);
                setPublicFiles(null);
            } else {
                logError(e, 'failed to sync public album with remote');
            }
        } finally {
            appContext.finishLoading();
            setLoading(false);
        }
    };

    const verifyLinkPassword: SingleInputFormProps['callback'] = async (
        password,
        setFieldError
    ) => {
        try {
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
            let hashedPassword: string = null;
            try {
                const publicUrl = publicCollection.publicURLs[0];
                hashedPassword = await cryptoWorker.deriveKey(
                    password,
                    publicUrl.nonce,
                    publicUrl.opsLimit,
                    publicUrl.memLimit
                );
            } catch (e) {
                logError(e, 'failed to derive key for verifyLinkPassword');
                setFieldError(`${constants.UNKNOWN_ERROR} ${e.message}`);
                return;
            }
            const collectionUID = getPublicCollectionUID(token.current);
            try {
                const jwtToken = await verifyPublicCollectionPassword(
                    token.current,
                    hashedPassword
                );
                passwordJWTToken.current = jwtToken;
                savePublicCollectionPassword(collectionUID, jwtToken);
            } catch (e) {
                const parsedError = parseSharingErrorCodes(e);
                if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                    setFieldError(constants.INCORRECT_PASSPHRASE);
                    return;
                }
                throw e;
            }
            await syncWithRemote();
            appContext.finishLoading();
        } catch (e) {
            logError(e, 'failed to verifyLinkPassword');
            setFieldError(`${constants.UNKNOWN_ERROR} ${e.message}`);
        }
    };

    if (loading) {
        if (!publicFiles) {
            return <Loader />;
        }
    } else {
        if (errorMessage) {
            return <VerticallyCentered>{errorMessage}</VerticallyCentered>;
        }
        if (isPasswordProtected && !passwordJWTToken.current) {
            return (
                <FormContainer>
                    <FormPaper>
                        <FormPaperTitle>{constants.PASSWORD}</FormPaperTitle>
                        <Typography
                            color={'text.secondary'}
                            mb={2}
                            variant="body2">
                            {constants.LINK_PASSWORD}
                        </Typography>
                        <SingleInputForm
                            callback={verifyLinkPassword}
                            placeholder={constants.RETURN_PASSPHRASE_HINT}
                            buttonText={'unlock'}
                            fieldType="password"
                        />
                    </FormPaper>
                </FormContainer>
            );
        }
        if (!publicFiles) {
            return (
                <VerticallyCentered>{constants.NOT_FOUND}</VerticallyCentered>
            );
        }
    }

    return (
        <PublicCollectionGalleryContext.Provider
            value={{
                token: token.current,
                passwordToken: passwordJWTToken.current,
                accessedThroughSharedURL: true,
                openReportForm,
                photoListHeader,
                photoListFooter,
            }}>
            <FullScreenDropZone
                getDragAndDropRootProps={getDragAndDropRootProps}>
                <UploadSelectorInputs
                    getDragAndDropInputProps={getDragAndDropInputProps}
                    getFileSelectorInputProps={getFileSelectorInputProps}
                    getFolderSelectorInputProps={getFolderSelectorInputProps}
                />
                <SharedAlbumNavbar
                    showUploadButton={
                        publicCollection?.publicURLs?.[0]?.enableCollect
                    }
                    openUploader={openUploader}
                />
                <PhotoFrame
                    files={publicFiles}
                    syncWithRemote={syncWithRemote}
                    setSelected={() => null}
                    selected={{ count: 0, collectionID: null }}
                    isFirstLoad={true}
                    activeCollection={ALL_SECTION}
                    isSharedCollection
                    enableDownload={
                        publicCollection?.publicURLs?.[0]?.enableDownload ??
                        true
                    }
                />
                <AbuseReportForm
                    show={abuseReportFormView}
                    close={closeReportForm}
                    url={url.current}
                />
                {blockingLoad && (
                    <LoadingOverlay>
                        <EnteSpinner />
                    </LoadingOverlay>
                )}
                <Uploader
                    syncWithRemote={syncWithRemote}
                    uploadCollection={publicCollection}
                    setLoading={setBlockingLoad}
                    setShouldDisableDropzone={setShouldDisableDropzone}
                    setFiles={setPublicFiles}
                    webFileSelectorFiles={webFileSelectorFiles}
                    webFolderSelectorFiles={webFolderSelectorFiles}
                    dragAndDropFiles={dragAndDropFiles}
                    uploadTypeSelectorView={uploadTypeSelectorView}
                    closeUploadTypeSelector={closeUploadTypeSelectorView}
                    showUploadFilesDialog={openFileSelector}
                    showUploadDirsDialog={openFolderSelector}
                    showSessionExpiredMessage={showPublicLinkExpiredMessage}
                    zipUploadDisabled
                />
            </FullScreenDropZone>
        </PublicCollectionGalleryContext.Provider>
    );
}
