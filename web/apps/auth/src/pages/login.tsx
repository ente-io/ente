import { Paper, Stack, styled } from "@mui/material";
import { LoginContents } from "ente-accounts/components/LoginContents";
import { savedPartialLocalUser } from "ente-accounts/services/accounts-db";
import { CenteredFill } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { LoadingIndicator } from "ente-base/components/loaders";
import { NavbarBase } from "ente-base/components/Navbar";
import { customAPIHost } from "ente-base/origins";
import { DevSettings } from "ente-new/photos/components/DevSettings";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";

const AccountsPagePaper = styled(Paper)(({ theme }) => ({
    marginBlock: theme.spacing(2),
    padding: theme.spacing(4, 2),
    width: "min(375px, 80vw)",
    minHeight: "375px",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(4),
}));

const Page: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>(undefined);
    const [showDevSettings, setShowDevSettings] = useState(false);
    const [tapCount, setTapCount] = useState(0);

    const router = useRouter();

    const refreshHost = useCallback(
        () => void customAPIHost().then(setHost),
        [],
    );

    useEffect(() => {
        refreshHost();
        if (savedPartialLocalUser()?.email) void router.replace("/verify");
        setLoading(false);
    }, [router, refreshHost]);

    const onSignUp = useCallback(() => void router.push("/signup"), [router]);

    const handleBackgroundClick: React.MouseEventHandler = (event) => {
        // Don't allow this when running on (e.g.) web.ente.io.
        if (!shouldAllowChangingAPIOrigin()) return;

        // Only count clicks directly on the background
        if (event.target !== event.currentTarget) return;

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
        refreshHost();
    };

    return loading ? (
        <LoadingIndicator />
    ) : (
        <Stack sx={{ minHeight: "100svh" }}>
            <NavbarBase
                sx={[
                    (theme) =>
                        theme.applyStyles("light", {
                            borderBottomColor: "stroke.base",
                        }),
                ]}
            >
                <EnteLogo />
            </NavbarBase>
            <CenteredFill
                onClick={handleBackgroundClick}
                sx={[
                    { bgcolor: "accent.main" },
                    (theme) =>
                        theme.applyStyles("dark", {
                            bgcolor: "background.default",
                        }),
                ]}
            >
                <AccountsPagePaper>
                    <LoginContents {...{ host, onSignUp }} />
                </AccountsPagePaper>
            </CenteredFill>
            <DevSettings open={showDevSettings} onClose={handleClose} />
        </Stack>
    );
};

export default Page;

/**
 * Disable the ability to set the custom server when we're running on our own
 * production deployment.
 */
const shouldAllowChangingAPIOrigin = () => {
    const hostname = new URL(window.location.origin).hostname;
    return !(hostname.endsWith(".ente.io") || hostname.endsWith(".ente.sh"));
};
