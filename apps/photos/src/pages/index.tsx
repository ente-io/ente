import React, { useContext, useEffect, useState } from 'react';
import Carousel from 'react-bootstrap/Carousel';
import { styled, Button, Typography, TypographyProps } from '@mui/material';
import { AppContext } from './_app';
import Login from '@ente/accounts/components/Login';
import { useRouter } from 'next/router';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import SignUp from '@ente/accounts/components/SignUp';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { t } from 'i18next';

import localForage from '@ente/shared/storage/localForage';
import { logError } from '@ente/shared/sentry';
import { PHOTOS_PAGES as PAGES } from '@ente/shared/constants/pages';
import { EnteLogo } from '@ente/shared/components/EnteLogo';
import isElectron from 'is-electron';
import ElectronAPIs from '@ente/shared/electron';
import { saveKeyInSessionStore } from '@ente/shared/crypto/helpers';
import { getKey, SESSION_KEYS } from '@ente/shared/storage/sessionStorage';
import { getAlbumsURL } from '@ente/shared/network/api';
import { Trans } from 'react-i18next';
import { APPS } from '@ente/shared/apps/constants';

const Container = styled('div')`
    display: flex;
    flex: 1;
    align-items: center;
    justify-content: center;
    background-color: #000;

    @media (max-width: 1024px) {
        flex-direction: column;
    }
`;

const SlideContainer = styled('div')`
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;

    @media (max-width: 1024px) {
        flex-grow: 0;
    }
`;

const DesktopBox = styled('div')`
    flex: 1;
    height: 100%;
    padding: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #242424;

    @media (max-width: 1024px) {
        display: none;
    }
`;

const MobileBox = styled('div')`
    display: none;

    @media (max-width: 1024px) {
        max-width: 375px;
        width: 100%;
        padding: 12px;
        display: flex;
        flex-direction: column;
        gap: 8px;
    }
`;

const SideBox = styled('div')`
    display: flex;
    flex-direction: column;
    min-width: 320px;
`;

const TextContainer = (props: TypographyProps) => (
    <Typography color={'text.muted'} mt={2} mb={3} {...props} />
);

const FeatureText = (props: TypographyProps) => (
    <Typography variant="h3" mt={4} {...props} />
);

const Img = styled('img')`
    height: 250px;
    object-fit: contain;

    @media (max-width: 400px) {
        height: 180px;
    }
`;

export default function LandingPage() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);
    const [showLogin, setShowLogin] = useState(true);

    useEffect(() => {
        appContext.showNavBar(false);
        const currentURL = new URL(window.location.href);
        const albumsURL = new URL(getAlbumsURL());
        currentURL.pathname = router.pathname;
        if (
            currentURL.host === albumsURL.host &&
            currentURL.pathname !== PAGES.SHARED_ALBUMS
        ) {
            handleAlbumsRedirect(currentURL);
        } else {
            handleNormalRedirect();
        }
    }, []);

    const handleAlbumsRedirect = async (currentURL: URL) => {
        const end = currentURL.hash.lastIndexOf('&');
        const hash = currentURL.hash.slice(1, end !== -1 ? end : undefined);
        await router.replace({
            pathname: PAGES.SHARED_ALBUMS,
            search: currentURL.search,
            hash: hash,
        });
        await initLocalForage();
    };

    const handleNormalRedirect = async () => {
        const user = getData(LS_KEYS.USER);
        let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key && isElectron()) {
            try {
                key = await ElectronAPIs.getEncryptionKey();
            } catch (e) {
                logError(e, 'getEncryptionKey failed');
            }
            if (key) {
                await saveKeyInSessionStore(
                    SESSION_KEYS.ENCRYPTION_KEY,
                    key,
                    true
                );
            }
        }
        if (key) {
            // if (appName === APPS.AUTH) {
            //     await router.push(PAGES.AUTH);
            // } else {
            await router.push(PAGES.GALLERY);
            // }
        } else if (user?.email) {
            await router.push(PAGES.VERIFY);
        } else {
            // if (appName === APPS.AUTH) {
            //     await router.push(PAGES.LOGIN);
            // }
        }
        await initLocalForage();
        setLoading(false);
    };

    const initLocalForage = async () => {
        try {
            await localForage.ready();
        } catch (e) {
            logError(e, 'usage in incognito mode tried');
            appContext.setDialogMessage({
                title: t('LOCAL_STORAGE_NOT_ACCESSIBLE'),

                nonClosable: true,
                content: t('LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE'),
            });
        } finally {
            setLoading(false);
        }
    };

    const signUp = () => setShowLogin(false);
    const login = () => setShowLogin(true);

    const redirectToSignupPage = () => router.push(PAGES.SIGNUP);
    const redirectToLoginPage = () => router.push(PAGES.LOGIN);

    return (
        <Container>
            {loading ? (
                <EnteSpinner />
            ) : (
                <>
                    <SlideContainer>
                        <EnteLogo height={24} sx={{ mb: 8 }} />
                        <Carousel controls={false}>
                            <Carousel.Item>
                                <Img
                                    src="/images/onboarding-lock/1x.png"
                                    srcSet="/images/onboarding-lock/2x.png 2x,
                                        /images/onboarding-lock/3x.png 3x"
                                />
                                <FeatureText>
                                    <Trans i18nKey={'HERO_SLIDE_1_TITLE'} />
                                </FeatureText>
                                <TextContainer>
                                    {t('HERO_SLIDE_1')}
                                </TextContainer>
                            </Carousel.Item>
                            <Carousel.Item>
                                <Img
                                    src="/images/onboarding-safe/1x.png"
                                    srcSet="/images/onboarding-safe/2x.png 2x,
                                        /images/onboarding-safe/3x.png 3x"
                                />
                                <FeatureText>
                                    <Trans i18nKey={'HERO_SLIDE_2_TITLE'} />
                                </FeatureText>
                                <TextContainer>
                                    {t('HERO_SLIDE_2')}
                                </TextContainer>
                            </Carousel.Item>
                            <Carousel.Item>
                                <Img
                                    src="/images/onboarding-sync/1x.png"
                                    srcSet="/images/onboarding-sync/2x.png 2x,
                                        /images/onboarding-sync/3x.png 3x"
                                />
                                <FeatureText>
                                    <Trans i18nKey={'HERO_SLIDE_3_TITLE'} />
                                </FeatureText>
                                <TextContainer>
                                    {t('HERO_SLIDE_3')}
                                </TextContainer>
                            </Carousel.Item>
                        </Carousel>
                    </SlideContainer>
                    <MobileBox>
                        <Button
                            color="accent"
                            size="large"
                            onClick={redirectToSignupPage}>
                            {t('NEW_USER')}
                        </Button>
                        <Button size="large" onClick={redirectToLoginPage}>
                            {t('EXISTING_USER')}
                        </Button>
                    </MobileBox>
                    <DesktopBox>
                        <SideBox>
                            {showLogin ? (
                                <Login signUp={signUp} appName={APPS.PHOTOS} />
                            ) : (
                                <SignUp
                                    router={router}
                                    appName={APPS.PHOTOS}
                                    login={login}
                                />
                            )}
                        </SideBox>
                    </DesktopBox>
                </>
            )}
        </Container>
    );
}
