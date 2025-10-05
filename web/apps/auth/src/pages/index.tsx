import { Box, Stack, Typography, styled } from "@mui/material";
import { LoginContents } from "ente-accounts/components/LoginContents";
import { SignUpContents } from "ente-accounts/components/SignUpContents";
import { savedPartialLocalUser } from "ente-accounts/services/accounts-db";
import { CenteredFill, CenteredRow } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { useBaseContext } from "ente-base/context";
import { customAPIHost } from "ente-base/origins";
import {
    masterKeyFromSession,
    updateSessionFromElectronSafeStorageIfNeeded,
} from "ente-base/session";
import { savedAuthToken } from "ente-base/token";
import { DevSettings } from "ente-new/base/components/DevSettings";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";

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
        void (async () => {
            refreshHost();
            const currentURL = new URL(window.location.href);
            currentURL.pathname = router.pathname;

            await updateSessionFromElectronSafeStorageIfNeeded();
            if (
                (await masterKeyFromSession()) &&
                (await savedAuthToken())
            ) {
                await router.push("/auth");
            } else if (savedPartialLocalUser()?.email) {
                await router.push("/verify");
            }

            setLoading(false);
        })();
    }, [showMiniDialog, router, refreshHost]);


    return (
        <TappableContainer onMaybeChangeHost={refreshHost}>
            {loading ? (
                <ActivityIndicator />
            ) : (
                <>
                    <MobileBox>
                        <FocusVisibleButton
                            color="accent"
                            onClick={() => router.push("/signup")}
                        >
                            {t("new_to_ente")}
                        </FocusVisibleButton>
                        <FocusVisibleButton
                            onClick={() => router.push("/login")}
                        >
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
                                    {...{ host }}
                                    onSignUp={() => setShowLogin(false)}
                                />
                            ) : (
                                <SignUpContents
                                    {...{ router, host }}
                                    onLogin={() => setShowLogin(true)}
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
