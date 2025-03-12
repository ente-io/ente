import { LoginContents } from "@/accounts/components/LoginContents";
import { SignUpContents } from "@/accounts/components/SignUpContents";
import { CenteredFill, CenteredRow } from "@/base/components/containers";
import { EnteLogo } from "@/base/components/EnteLogo";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { useBaseContext } from "@/base/context";
import log from "@/base/log";
import { albumsAppOrigin, customAPIHost } from "@/base/origins";
import { DevSettings } from "@/new/photos/components/DevSettings";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { saveKeyInSessionStore } from "@ente/shared/crypto/helpers";
import localForage from "@ente/shared/storage/localForage";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { SESSION_KEYS, getKey } from "@ente/shared/storage/sessionStorage";
import { Box, Stack, Typography, styled } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import { Trans } from "react-i18next";

const Page: React.FC = () => {
    const { showMiniDialog } = useBaseContext();

    const [loading, setLoading] = useState(true);
    const [showLogin, setShowLogin] = useState(true);
    const [host, setHost] = useState<string | undefined>(undefined);

    const router = useRouter();

    const refreshHost = useCallback(
        () => void customAPIHost().then(setHost),
        [],
    );

    useEffect(() => {
        refreshHost();
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
                key = await electron.masterKeyB64();
            } catch (e) {
                log.error("Failed to read master key from safe storage", e);
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
            log.error("Local storage is not accessible", e);
            showMiniDialog({
                title: t("error"),
                message: t("LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE"),
                nonClosable: true,
                cancel: false,
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
                <ActivityIndicator />
            ) : (
                <>
                    <SlideshowPanel>
                        <Logo_>
                            <EnteLogo height={24} />
                        </Logo_>
                        <Slideshow />
                    </SlideshowPanel>
                    <MobileBox>
                        <FocusVisibleButton
                            color="accent"
                            onClick={redirectToSignupPage}
                        >
                            {t("new_to_ente")}
                        </FocusVisibleButton>
                        <FocusVisibleButton onClick={redirectToLoginPage}>
                            {t("existing_user")}
                        </FocusVisibleButton>
                        <MobileBoxFooter {...{ host }} />
                    </MobileBox>
                    <DesktopBox
                        sx={[
                            { bgcolor: "background.default" },
                            (theme) =>
                                theme.applyStyles("dark", {
                                    bgcolor: "background.paper2",
                                }),
                        ]}
                    >
                        <Stack sx={{ width: "320px", py: 4, gap: 4 }}>
                            {showLogin ? (
                                <LoginContents
                                    {...{ onSignUp: signUp, host }}
                                />
                            ) : (
                                <SignUpContents
                                    {...{ router, onLogin: login, host }}
                                />
                            )}
                        </Stack>
                    </DesktopBox>
                </>
            )}
        </TappableContainer>
    );
};

export default Page;

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
        <CenteredFill
            sx={[
                {
                    bgcolor: "background.paper2",
                    "@media (width <= 1024px)": { flexDirection: "column" },
                },
                (theme) =>
                    theme.applyStyles("dark", {
                        bgcolor: "background.default",
                    }),
            ]}
            onClick={handleClick}
        >
            <DevSettings open={showDevSettings} onClose={handleClose} />
            {children}
        </CenteredFill>
    );
};

/**
 * Disable the ability to set the custom server when we're running on our own
 * production deployment.
 */
const shouldAllowChangingAPIOrigin = () => {
    const hostname = new URL(window.location.origin).hostname;
    return !(hostname.endsWith(".ente.io") || hostname.endsWith(".ente.sh"));
};

const SlideshowPanel = styled("div")`
    align-self: stretch;

    flex-shrink: 1;
    flex-grow: 1;
    flex-basis: auto;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;

    @media (width <= 1024px) {
        flex-grow: 0;
    }
    @media (width > 1024px) {
        width: 700px;
    }
`;

const Logo_ = styled("div")`
    /* Bias towards the left for better visual alignment with the slides. */
    padding-inline-end: 1rem;

    margin-block-start: 32px;
    margin-block-end: 40px;
    @media (width >= 1024px) {
        margin-block-end: 48px;
    }
`;

const MobileBox = styled("div")`
    display: none;

    @media (width <= 1024px) {
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
        <Box sx={{ pt: 4, textAlign: "center" }}>
            {host && (
                <Typography variant="mini" sx={{ color: "text.faint" }}>
                    {host}
                </Typography>
            )}
        </Box>
    );
};

const DesktopBox = styled(CenteredRow)`
    flex-shrink: 0;
    flex-grow: 2;
    flex-basis: auto;

    height: 100%;
    padding-inline: 20px;

    @media (width <= 1024px) {
        display: none;
    }
`;

const Slideshow: React.FC = () => {
    const [selectedIndex, setSelectedIndex] = useState(0);
    const containerRef = useRef<HTMLDivElement | undefined>(undefined);

    useEffect(() => {
        const intervalID = setInterval(() => {
            setSelectedIndex((selectedIndex + 1) % 3);
        }, 5000);
        return () => clearInterval(intervalID);
    });

    useEffect(() => {
        const container = containerRef.current!;
        const left = containerRef.current!.offsetWidth * selectedIndex;
        // Smooth scroll doesn't work with Chrome intermittently. A common
        // workaround is to wrap the scrollTo in a setTimeout etc, but even that
        // doesn't help for our particular scenario.
        //
        // Ref: https://github.com/facebook/react/issues/23396
        //
        // As an alternative, scroll twice (once smoothly, once without) to the
        // same position so that at least the fallback works on Chrome.
        container.scrollTo({ left, behavior: "smooth" });
        setTimeout(() => container.scrollTo({ left }), 500);
    }, [selectedIndex]);

    return (
        <SlidesContainer ref={containerRef}>
            <Slide>
                <Img
                    src="/images/onboarding-lock/1x.png"
                    srcSet="/images/onboarding-lock/2x.png 2x, /images/onboarding-lock/3x.png 3x"
                />
                <SlideTitle>
                    <Trans i18nKey={"intro_slide_1_title"} />
                </SlideTitle>
                <SlideDescription>{t("intro_slide_1")}</SlideDescription>
            </Slide>
            <Slide>
                <Img
                    src="/images/onboarding-safe/1x.png"
                    srcSet="/images/onboarding-safe/2x.png 2x, /images/onboarding-safe/3x.png 3x"
                />
                <SlideTitle>
                    <Trans i18nKey={"intro_slide_2_title"} />
                </SlideTitle>
                <SlideDescription>{t("intro_slide_2")}</SlideDescription>
            </Slide>
            <Slide>
                <Img
                    src="/images/onboarding-sync/1x.png"
                    srcSet="/images/onboarding-sync/2x.png 2x, /images/onboarding-sync/3x.png 3x"
                />
                <SlideTitle>
                    <Trans i18nKey={"intro_slide_3_title"} />
                </SlideTitle>
                <SlideDescription>{t("intro_slide_3")}</SlideDescription>
            </Slide>
        </SlidesContainer>
    );
};

const SlidesContainer = styled("div")`
    /* Override the center align for ourselves so that we don't revert back to
       our intrinsic width. */
    align-self: stretch;
    display: flex;
    overflow-x: hidden;
`;

const Slide = styled(Stack)`
    min-width: 100%;
    align-items: center;
    text-align: center;
`;

const SlideTitle: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Typography variant="h3" sx={{ mt: 4 }}>
        {children}
    </Typography>
);

const SlideDescription: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Typography sx={{ color: "text.muted", mt: 2, mb: 3 }}>
        {children}
    </Typography>
);

const Img = styled("img")`
    height: 250px;
    object-fit: contain;

    @media (width <= 400px) {
        height: 180px;
    }
`;
