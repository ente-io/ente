import { DevSettings } from "@/new/photos/components/DevSettings";
import log from "@/next/log";
import { albumsAppOrigin, customAPIHost } from "@/next/origins";
import { Login } from "@ente/accounts/components/Login";
import { SignUp } from "@ente/accounts/components/SignUp";
import { EnteLogo } from "@ente/shared/components/EnteLogo";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { saveKeyInSessionStore } from "@ente/shared/crypto/helpers";
import localForage from "@ente/shared/storage/localForage";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { SESSION_KEYS, getKey } from "@ente/shared/storage/sessionStorage";
import {
    Box,
    Button,
    Typography,
    styled,
    type TypographyProps,
} from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { CarouselProvider, DotGroup, Slide, Slider } from "pure-react-carousel";
import "pure-react-carousel/dist/react-carousel.es.css";
import { useCallback, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { useAppContext } from "./_app";

export default function LandingPage() {
    const { appName, showNavBar, setDialogMessage } = useAppContext();

    const [loading, setLoading] = useState(true);
    const [showLogin, setShowLogin] = useState(true);
    const [host, setHost] = useState<string | undefined>();

    const router = useRouter();

    const refreshHost = useCallback(
        () => void customAPIHost().then(setHost),
        [],
    );

    useEffect(() => {
        refreshHost();
        showNavBar(false);
        const currentURL = new URL(window.location.href);
        const albumsURL = new URL(albumsAppOrigin());
        currentURL.pathname = router.pathname;
        if (
            currentURL.host === albumsURL.host &&
            currentURL.pathname !== PAGES.SHARED_ALBUMS
        ) {
            handleAlbumsRedirect(currentURL);
        } else {
            handleNormalRedirect();
        }
    }, [refreshHost]);

    const handleAlbumsRedirect = async (currentURL: URL) => {
        const end = currentURL.hash.lastIndexOf("&");
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
        const electron = globalThis.electron;
        if (!key && electron) {
            try {
                key = await electron.encryptionKey();
            } catch (e) {
                log.error("Failed to get encryption key from electron", e);
            }
            if (key) {
                await saveKeyInSessionStore(
                    SESSION_KEYS.ENCRYPTION_KEY,
                    key,
                    true,
                );
            }
        }
        const token = getToken();
        if (key && token) {
            await router.push(PAGES.GALLERY);
        } else if (user?.email) {
            await router.push(PAGES.VERIFY);
        }
        await initLocalForage();
        setLoading(false);
    };

    const initLocalForage = async () => {
        try {
            await localForage.ready();
        } catch (e) {
            log.error("usage in incognito mode tried", e);
            setDialogMessage({
                title: t("LOCAL_STORAGE_NOT_ACCESSIBLE"),

                nonClosable: true,
                content: t("LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE"),
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
        <TappableContainer onMaybeChangeHost={refreshHost}>
            {loading ? (
                <EnteSpinner />
            ) : (
                <>
                    <SlideContainer>
                        <Logo_>
                            <EnteLogo height={24} />
                        </Logo_>
                        <Slideshow />
                    </SlideContainer>
                    <MobileBox>
                        <Button
                            color="accent"
                            size="large"
                            onClick={redirectToSignupPage}
                        >
                            {t("NEW_USER")}
                        </Button>
                        <Button size="large" onClick={redirectToLoginPage}>
                            {t("EXISTING_USER")}
                        </Button>
                        <MobileBoxFooter {...{ host }} />
                    </MobileBox>
                    <DesktopBox>
                        <SideBox>
                            {showLogin ? (
                                <Login {...{ signUp, appName, host }} />
                            ) : (
                                <SignUp {...{ router, appName, login, host }} />
                            )}
                        </SideBox>
                    </DesktopBox>
                </>
            )}
        </TappableContainer>
    );
}

interface TappableContainerProps {
    /**
     * Called when the user closes the dialog to set a custom server.
     *
     * This is our chance to re-read the value of the custom API origin from
     * local storage since the user might've changed it.
     */
    onMaybeChangeHost: () => void;
}

const TappableContainer: React.FC<
    React.PropsWithChildren<TappableContainerProps>
> = ({ onMaybeChangeHost, children }) => {
    // [Note: Configuring custom server]
    //
    // Allow the user to tap 7 times anywhere on the onboarding screen to bring
    // up a page where they can configure the endpoint that the app should
    // connect to.
    //
    // See: https://help.ente.io/self-hosting/guides/custom-server/
    const [tapCount, setTapCount] = useState(0);
    const [showDevSettings, setShowDevSettings] = useState(false);

    const handleClick: React.MouseEventHandler = (event) => {
        // Don't allow this when running on (e.g.) web.ente.io.
        if (!shouldAllowChangingAPIOrigin()) return;

        // Ignore clicks on buttons when counting up towards 7.
        if (event.target instanceof HTMLButtonElement) return;

        // Ignore clicks when the dialog is already open.
        if (showDevSettings) return;

        // Otherwise increase the tap count,
        setTapCount(tapCount + 1);
        // And show the dev settings dialog when it reaches 7.
        if (tapCount + 1 == 7) {
            setTapCount(0);
            setShowDevSettings(true);
        }
    };

    const handleClose = () => {
        setShowDevSettings(false);
        onMaybeChangeHost();
    };

    return (
        <TappableContainer_ onClick={handleClick}>
            <>
                <DevSettings open={showDevSettings} onClose={handleClose} />
                {children}
            </>
        </TappableContainer_>
    );
};

const TappableContainer_ = styled("div")`
    display: flex;
    flex: 1;
    align-items: center;
    justify-content: center;
    background-color: #000;

    @media (max-width: 1024px) {
        flex-direction: column;
    }
`;

/**
 * Disable the ability to set the custom server when we're running on our own
 * production deployment.
 */
const shouldAllowChangingAPIOrigin = () => {
    const hostname = new URL(window.location.origin).hostname;
    return !(hostname.endsWith(".ente.io") || hostname.endsWith(".ente.sh"));
};

const SlideContainer = styled("div")`
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

const Logo_ = styled("div")`
    margin-block-end: 64px;
`;

const MobileBox = styled("div")`
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

interface MobileBoxFooterProps {
    host: string | undefined;
}

const MobileBoxFooter: React.FC<MobileBoxFooterProps> = ({ host }) => {
    return (
        <Box pt={4} textAlign="center">
            {host && (
                <Typography variant="mini" color="text.faint">
                    {host}
                </Typography>
            )}
        </Box>
    );
};

const DesktopBox = styled("div")`
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

const SideBox = styled("div")`
    display: flex;
    flex-direction: column;
    min-width: 320px;
`;

const Slideshow: React.FC = () => {
    return (
        <CarouselProvider
            naturalSlideWidth={400}
            naturalSlideHeight={300}
            isIntrinsicHeight={true}
            totalSlides={3}
            isPlaying={true}
        >
            <Slider>
                <Slide index={0}>
                    <Img
                        src="/images/onboarding-lock/1x.png"
                        srcSet="/images/onboarding-lock/2x.png 2x,
/images/onboarding-lock/3x.png 3x"
                    />
                    <FeatureText>
                        <Trans i18nKey={"HERO_SLIDE_1_TITLE"} />
                    </FeatureText>
                    <TextContainer>{t("HERO_SLIDE_1")}</TextContainer>
                </Slide>
                <Slide index={1}>
                    <SlideContents>
                        <Img
                            src="/images/onboarding-safe/1x.png"
                            srcSet="/images/onboarding-safe/2x.png 2x,
                /images/onboarding-safe/3x.png 3x"
                        />
                        <FeatureText>
                            <Trans i18nKey={"HERO_SLIDE_2_TITLE"} />
                        </FeatureText>
                        <TextContainer>{t("HERO_SLIDE_2")}</TextContainer>
                    </SlideContents>
                </Slide>
                <Slide index={2}>
                    <SlideContents>
                        <Img
                            src="/images/onboarding-sync/1x.png"
                            srcSet="/images/onboarding-sync/2x.png 2x,
                /images/onboarding-sync/3x.png 3x"
                        />
                        <FeatureText>
                            <Trans i18nKey={"HERO_SLIDE_3_TITLE"} />
                        </FeatureText>
                        <TextContainer>{t("HERO_SLIDE_3")}</TextContainer>
                    </SlideContents>
                </Slide>
            </Slider>
            <CustomDotGroup />
        </CarouselProvider>
    );
};

const TextContainer = (props: TypographyProps) => (
    <Typography color={"text.muted"} mt={2} mb={3} {...props} />
);

const FeatureText = (props: TypographyProps) => (
    <Typography variant="h3" mt={4} {...props} />
);

const Img = styled("img")`
    height: 250px;
    object-fit: contain;

    @media (max-width: 400px) {
        height: 180px;
    }
`;

const CustomDotGroup = styled(DotGroup)`
    margin-block-start: 2px;
    margin-block-end: 24px;

    button {
        margin-inline-end: 14px;
        width: 10px;
        height: 10px;
        border-radius: 50%;
        padding: 0;
        border: 0;
        background-color: #fff;
        opacity: 0.5;
        transition: opacity 0.6s ease;
    }

    button.carousel__dot--selected {
        background-color: #51cd7c;
        opacity: 1;
    }
`;

const SlideContents = styled("div")`
    display: flex;
    flex-direction: column;
`;
