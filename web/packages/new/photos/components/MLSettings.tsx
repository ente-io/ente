import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup } from "@/base/components/Menu";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Titlebar } from "@/base/components/Titlebar";
import type { NestedDrawerVisibilityProps } from "@/base/components/utils/modal";
import {
    disableML,
    enableML,
    mlStatusSnapshot,
    mlStatusSubscribe,
    type MLStatus,
} from "@/new/photos/services/ml";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import {
    Box,
    Button,
    Checkbox,
    Divider,
    FormControlLabel,
    FormGroup,
    Link,
    Paper,
    Stack,
    Typography,
    type DialogProps,
} from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState, useSyncExternalStore } from "react";
import { Trans } from "react-i18next";
import { useAppContext } from "../types/context";
import { openURL } from "../utils/web";
import { useWrapAsyncOperation } from "./use-wrap-async";

export const MLSettings: React.FC<NestedDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const mlStatus = useSyncExternalStore(mlStatusSubscribe, mlStatusSnapshot);
    const [openFaceConsent, setOpenFaceConsent] = useState(false);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") handleRootClose();
        else onClose();
    };

    const handleEnableML = () => setOpenFaceConsent(true);

    const handleConsent = useWrapAsyncOperation(async () => {
        await enableML();
        // Close the FaceConsent drawer, come back to ourselves.
        setOpenFaceConsent(false);
    });

    const handleDisableML = useWrapAsyncOperation(disableML);

    let component: React.ReactNode;
    if (!mlStatus) {
        component = <Loading />;
    } else if (mlStatus.phase == "disabled") {
        component = <EnableML onEnable={handleEnableML} />;
    } else {
        component = (
            <ManageML {...{ mlStatus }} onDisableML={handleDisableML} />
        );
    }

    return (
        <Box>
            <EnteDrawer
                anchor="left"
                transitionDuration={0}
                open={open}
                onClose={handleDrawerClose}
                BackdropProps={{
                    sx: { "&&&": { backgroundColor: "transparent" } },
                }}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={onClose}
                        title={t("ml_search")}
                        onRootClose={onRootClose}
                    />
                    {component}
                </Stack>
            </EnteDrawer>

            <FaceConsent
                open={openFaceConsent}
                onClose={() => setOpenFaceConsent(false)}
                onRootClose={handleRootClose}
                onConsent={handleConsent}
            />
        </Box>
    );
};

const Loading: React.FC = () => {
    return (
        <Box textAlign="center" pt={4}>
            <ActivityIndicator />
        </Box>
    );
};

interface EnableMLProps {
    /** Called when the user enables ML. */
    onEnable: () => void;
}

const EnableML: React.FC<EnableMLProps> = ({ onEnable }) => {
    const moreDetails = () =>
        openURL("https://help.ente.io/photos/features/machine-learning");

    return (
        <Stack py={"20px"} px={"16px"} spacing={"32px"}>
            <Typography color="text.muted">
                {t("ml_search_description")}
            </Typography>
            <Stack spacing={"8px"}>
                <Button color={"accent"} size="large" onClick={onEnable}>
                    {t("enable")}
                </Button>

                <Button color="secondary" size="large" onClick={moreDetails}>
                    {t("more_details")}
                </Button>
            </Stack>
            <Typography color="text.faint" variant="small">
                {t("ml_search_footnote")}
            </Typography>
        </Stack>
    );
};

type FaceConsentProps = NestedDrawerVisibilityProps & {
    /** Called when the user provides their consent. */
    onConsent: () => void;
};

const FaceConsent: React.FC<FaceConsentProps> = ({
    open,
    onClose,
    onRootClose,
    onConsent,
}) => {
    const [acceptTerms, setAcceptTerms] = useState(false);

    useEffect(() => {
        setAcceptTerms(false);
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") handleRootClose();
        else onClose();
    };

    const privacyPolicyLink = (
        <Link
            target="_blank"
            href="https://ente.io/privacy#8-biometric-information-privacy-policy"
            underline="always"
            sx={{
                color: "inherit",
                textDecorationColor: "inherit",
            }}
        />
    );

    return (
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={handleDrawerClose}
            BackdropProps={{
                sx: { "&&&": { backgroundColor: "transparent" } },
            }}
        >
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("ml_consent_title")}
                    onRootClose={handleRootClose}
                />
                <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                    <Typography component="div" color="text.muted" px={"8px"}>
                        <Trans
                            i18nKey={"ml_consent_description"}
                            components={{ a: privacyPolicyLink }}
                        />
                    </Typography>
                    <FormGroup sx={{ width: "100%" }}>
                        <FormControlLabel
                            sx={{
                                color: "text.muted",
                                ml: 0,
                                mt: 2,
                            }}
                            control={
                                <Checkbox
                                    size="small"
                                    checked={acceptTerms}
                                    onChange={(e) =>
                                        setAcceptTerms(e.target.checked)
                                    }
                                />
                            }
                            label={t("ml_consent_confirmation")}
                        />
                    </FormGroup>
                    <Stack px={"8px"} spacing={"8px"}>
                        <Button
                            color={"accent"}
                            size="large"
                            disabled={!acceptTerms}
                            onClick={onConsent}
                        >
                            {t("ml_consent")}
                        </Button>
                        <Button
                            color={"secondary"}
                            size="large"
                            onClick={onClose}
                        >
                            {t("cancel")}
                        </Button>
                    </Stack>
                </Stack>
            </Stack>
        </EnteDrawer>
    );
};

interface ManageMLProps {
    /** The {@link MLStatus}; a non-disabled one. */
    mlStatus: Exclude<MLStatus, { phase: "disabled" }>;
    /** Called when the user wants to disable ML. */
    onDisableML: () => void;
}

const ManageML: React.FC<ManageMLProps> = ({ mlStatus, onDisableML }) => {
    const { showMiniDialog } = useAppContext();

    const { phase, nSyncedFiles, nTotalFiles } = mlStatus;

    let status: string;
    switch (phase) {
        case "scheduled":
            status = t("indexing_status_scheduled");
            break;
        case "fetching":
            status = t("indexing_status_fetching");
            break;
        case "indexing":
            status = t("indexing_status_running");
            break;
        case "clustering":
            status = t("people");
            break;
        default:
            status = t("indexing_status_done");
            break;
    }

    // When clustering, show the progress as a percentage instead of the
    // potentially confusing total counts during incremental updates.
    const processed =
        phase == "clustering"
            ? `${Math.round((100 * nSyncedFiles) / nTotalFiles)}%`
            : `${nSyncedFiles} / ${nTotalFiles}`;

    const confirmDisableML = () =>
        showMiniDialog({
            title: t("ml_search_disable"),
            message: t("ml_search_disable_confirm"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: onDisableML,
            },
        });

    return (
        <Stack px={"16px"} py={"20px"} gap={4}>
            <Stack gap={3}>
                <MenuItemGroup>
                    <EnteMenuItem
                        label={t("enabled")}
                        variant="toggle"
                        checked={true}
                        onClick={confirmDisableML}
                    />
                </MenuItemGroup>
            </Stack>
            <Paper variant="outlined">
                <Stack>
                    <Stack
                        direction="row"
                        gap={2}
                        px={2}
                        pt={1}
                        pb={2}
                        justifyContent={"space-between"}
                    >
                        <Typography color="text.faint">
                            {t("indexing")}
                        </Typography>
                        <Typography>{status}</Typography>
                    </Stack>
                    <Divider sx={{ marginInlineStart: 2 }} />
                    <Stack
                        direction="row"
                        gap={2}
                        px={2}
                        pt={2}
                        pb={1}
                        justifyContent={"space-between"}
                    >
                        <Typography color="text.faint">
                            {t("processed")}
                        </Typography>
                        <Typography textAlign="right">{processed}</Typography>
                    </Stack>
                </Stack>
            </Paper>
        </Stack>
    );
};
