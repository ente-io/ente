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
import {
    defaultPublicCollectionGalleryContext,
    PublicCollectionGalleryContext,
} from 'utils/publicCollectionGallery';
import { CustomError, parseSharingErrorCodes } from 'utils/error';
import VerticallyCentered from 'components/Container';
import constants from 'utils/strings/constants';
import EnteSpinner from 'components/EnteSpinner';
import CryptoWorker from 'utils/crypto';
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

const Loader = () => (
    <VerticallyCentered>
        <EnteSpinner>
            <span className="sr-only">Loading...</span>
        </EnteSpinner>
    </VerticallyCentered>
);
const bs58 = require('bs58');
export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    // passwordJWTToken refers to the jwt token which is used for album protected by password.
    const passwordJWTToken = useRef<string>(null);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const [errorMessage, setErrorMessage] = useState<String>(null);
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
                const worker = await new CryptoWorker();
                url.current = window.location.href;
                const currentURL = new URL(url.current);
                const t = currentURL.searchParams.get('t');
                const ck = currentURL.hash.slice(1);
                if (!t || !ck) {
                    return;
                }
                const dck =
                    ck.length < 50
                        ? await worker.toB64(bs58.decode(ck))
                        : await worker.fromHex(ck);
                token.current = t;
                collectionKey.current = dck;
                url.current = window.location.href;
                const localCollection = await getLocalPublicCollection(
                    collectionKey.current
                );
                if (localCollection) {
                    setPublicCollection(localCollection);
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

    useEffect(
        () =>
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
                itemType: ITEM_TYPE.OTHER,
                height: 68,
            }),
        [publicCollection, publicFiles]
    );

    const syncWithRemote = async () => {
        const collectionUID = getPublicCollectionUID(token.current);
        try {
            appContext.startLoading();
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
                        : constants.LINK_EXPIRED
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
        }
    };

    const verifyLinkPassword: SingleInputFormProps['callback'] = async (
        password,
        setFieldError
    ) => {
        try {
            const cryptoWorker = await new CryptoWorker();
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
                ...defaultPublicCollectionGalleryContext,
                token: token.current,
                passwordToken: passwordJWTToken.current,
                accessedThroughSharedURL: true,
                openReportForm,
                photoListHeader,
            }}>
            <SharedAlbumNavbar />
            <PhotoFrame
                files={publicFiles}
                setFiles={setPublicFiles}
                syncWithRemote={syncWithRemote}
                favItemIds={null}
                setSelected={() => null}
                selected={{ count: 0, collectionID: null }}
                isFirstLoad={true}
                openUploader={() => null}
                isInSearchMode={false}
                search={{}}
                deletedFileIds={new Set<number>()}
                activeCollection={ALL_SECTION}
                isSharedCollection
                enableDownload={
                    publicCollection?.publicURLs?.[0]?.enableDownload ?? true
                }
            />
            <AbuseReportForm
                show={abuseReportFormView}
                close={closeReportForm}
                url={url.current}
            />
        </PublicCollectionGalleryContext.Provider>
    );
}
