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
    savePublicCollectionPassword,
    syncPublicFiles,
    verifyPublicCollectionPassword,
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
import { useRouter } from 'next/router';
import LogoImg from 'components/LogoImg';
import SingleInputForm from 'components/SingleInputForm';
import { Card } from 'react-bootstrap';
import { logError } from 'utils/sentry';

const Loader = () => (
    <Container>
        <EnteSpinner>
            <span className="sr-only">Loading...</span>
        </EnteSpinner>
    </Container>
);
const bs58 = require('bs58');
export default function PublicCollectionGallery() {
    const token = useRef<string>(null);
    // passwordJWTToken refers to the jwt token which is used for album protected by password.
    const [passwordJWTToken, setPasswordJWTToken] = useState<string>(null);
    const collectionKey = useRef<string>(null);
    const url = useRef<string>(null);
    const [publicFiles, setPublicFiles] = useState<EnteFile[]>(null);
    const [publicCollection, setPublicCollection] = useState<Collection>(null);
    const [errorMessage, setErrorMessage] = useState<String>(null);
    const appContext = useContext(AppContext);
    const [abuseReportFormView, setAbuseReportFormView] = useState(false);
    const [dialogMessage, setDialogMessage] = useState<MessageAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [loading, setLoading] = useState(true);
    const openReportForm = () => setAbuseReportFormView(true);
    const closeReportForm = () => setAbuseReportFormView(false);
    const loadingBar = useRef(null);
    const isLoadingBarRunning = useRef(false);
    const router = useRouter();
    const [isPasswordProtected, setIsPasswordProtected] =
        useState<boolean>(false);

    const openMessageDialog = () => setMessageDialogView(true);
    const closeMessageDialog = () => setMessageDialogView(false);

    const startLoadingBar = () => {
        !isLoadingBarRunning.current && loadingBar.current?.continuousStart();
        isLoadingBarRunning.current = true;
    };
    const finishLoadingBar = () => {
        isLoadingBarRunning.current && loadingBar.current?.complete();
        isLoadingBarRunning.current = false;
    };

    useEffect(() => {
        appContext.showNavBar(true);
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
                    const localPasswordJWTToken =
                        await getLocalPublicCollectionPassword(collectionUID);

                    setPublicFiles(localPublicFiles);
                    setPasswordJWTToken(localPasswordJWTToken);
                }
                await syncWithRemote();
            } finally {
                setLoading(false);
            }
        };
        main();
    }, []);

    useEffect(openMessageDialog, [dialogMessage]);

    const syncWithRemote = async () => {
        try {
            startLoadingBar();
            const collection = await getPublicCollection(
                token.current,
                collectionKey.current
            );
            setPublicCollection(collection);
            setErrorMessage(null);
            // check if we need to prompt user for the password
            if (
                (collection?.publicURLs?.[0]?.passwordEnabled ?? false) &&
                !passwordJWTToken
            ) {
                setIsPasswordProtected(true);
            } else {
                await syncPublicFiles(
                    token.current,
                    collection,
                    setPublicFiles
                );
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
                    token.current,
                    collectionKey.current
                );
                setPublicCollection(null);
                setPublicFiles(null);
            }
        } finally {
            finishLoadingBar();
        }
    };

    const verifyLinkPassword = async (password, setFieldError) => {
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
                setFieldError(
                    'passphrase',
                    `${constants.UNKNOWN_ERROR} ${e.message}`
                );
                return;
            }
            const collectionUID = getPublicCollectionUID(token.current);
            try {
                const jwtToken = await verifyPublicCollectionPassword(
                    token.current,
                    hashedPassword
                );
                setPasswordJWTToken(jwtToken);
                savePublicCollectionPassword(collectionUID, jwtToken);
            } catch (e) {
                // reset local password token
                logError(e, 'failed to validate password for album');
                const parsedError = parseSharingErrorCodes(e);
                if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                    setFieldError('passphrase', constants.INCORRECT_PASSPHRASE);
                    return;
                }
                throw e;
            }
            await syncWithRemote();
            finishLoadingBar();
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`
            );
        }
    };

    if (!publicFiles && loading) {
        return <Loader />;
    }

    if (errorMessage && !loading) {
        return <Container>{errorMessage}</Container>;
    }
    if (isPasswordProtected && !passwordJWTToken && !loading) {
        return (
            <Container>
                <Card style={{ width: '332px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '24px' }}>
                            <LogoImg src="/icon.svg" />
                            {constants.PASSWORD}
                        </Card.Title>
                        <Card.Subtitle style={{ marginBottom: '2rem' }}>
                            {/* <LogoImg src="/icon.svg" /> */}
                            {constants.LINK_PASSWORD}
                        </Card.Subtitle>
                        <SingleInputForm
                            callback={verifyLinkPassword}
                            placeholder={constants.RETURN_PASSPHRASE_HINT}
                            buttonText={'unlock'}
                            fieldType="password"
                        />
                    </Card.Body>
                </Card>
            </Container>
        );
    }

    if (!publicFiles && !loading) {
        return <Container>{constants.NOT_FOUND}</Container>;
    }

    return (
        <PublicCollectionGalleryContext.Provider
            value={{
                ...defaultPublicCollectionGalleryContext,
                token: token.current,
                passwordToken: passwordJWTToken,
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
                enableDownload={
                    publicCollection?.publicURLs?.[0]?.enableDownload ?? true
                }
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
