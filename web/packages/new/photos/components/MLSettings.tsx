import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import { pt, ut } from "@/base/i18n";
import log from "@/base/log";
import {
    disableML,
    enableML,
    mlStatusSnapshot,
    mlStatusSubscribe,
    wipClusterEnable,
    type MLStatus,
} from "@/new/photos/services/ml";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
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
import { useRouter } from "next/router";
import React, { useEffect, useState, useSyncExternalStore } from "react";
import { Trans } from "react-i18next";
import type { NewAppContextPhotos } from "../types/context";
import { openURL } from "../utils/web";

interface MLSettingsProps {
    /** If `true`, then this drawer page is shown. */
    open: boolean;
    /** Called when the user wants to go back from this drawer page. */
    onClose: () => void;
    /** Called when the user wants to close the entire stack of drawers. */
    onRootClose: () => void;
    /** See: [Note: Migrating components that need the app context]. */
    appContext: NewAppContextPhotos;
}

export const MLSettings: React.FC<MLSettingsProps> = ({
    open,
    onClose,
    onRootClose,
    appContext,
}) => {
    const {
        startLoading,
        finishLoading,
        setDialogBoxAttributesV2,
        somethingWentWrong,
    } = appContext;

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

    const handleConsent = async () => {
        startLoading();
        try {
            await enableML();
            // Close the FaceConsent drawer, come back to ourselves.
            setOpenFaceConsent(false);
        } catch (e) {
            log.error("Failed to enable ML", e);
            somethingWentWrong();
        } finally {
            finishLoading();
        }
    };

    const handleDisableML = async () => {
        startLoading();
        try {
            await disableML();
        } catch (e) {
            log.error("Failed to disable ML", e);
            somethingWentWrong();
        } finally {
            finishLoading();
        }
    };

    let component: React.ReactNode;
    if (!mlStatus) {
        component = <Loading />;
    } else if (mlStatus.phase == "disabled") {
        component = <EnableML onEnable={handleEnableML} />;
    } else {
        component = (
            <ManageML
                {...{ mlStatus, setDialogBoxAttributesV2 }}
                onDisableML={handleDisableML}
            />
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
            <EnteSpinner />
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

type FaceConsentProps = Omit<MLSettingsProps, "appContext"> & {
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
    /** Subset of appContext. */
    setDialogBoxAttributesV2: NewAppContextPhotos["setDialogBoxAttributesV2"];
}

const ManageML: React.FC<ManageMLProps> = ({
    mlStatus,
    onDisableML,
    setDialogBoxAttributesV2,
}) => {
    const [showClusterOpt, setShowClusterOpt] = useState(false);
    const { phase, nSyncedFiles, nTotalFiles } = mlStatus;

    useEffect(() => void wipClusterEnable().then(setShowClusterOpt), []);

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
            // TODO-Cluster
            status = pt("Grouping faces");
            break;
        default:
            status = t("indexing_status_done");
            break;
    }
    const processed = `${nSyncedFiles} / ${nTotalFiles}`;

    const confirmDisableML = () => {
        setDialogBoxAttributesV2({
            title: t("ml_search_disable"),
            content: t("ml_search_disable_confirm"),
            close: { text: t("cancel") },
            proceed: {
                variant: "critical",
                text: t("disable"),
                action: onDisableML,
            },
            buttonDirection: "row",
        });
    };

    // TODO-Cluster
    const router = useRouter();
    const wipClusterDebug = () => router.push("/cluster-debug");

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
            {showClusterOpt && (
                <Box>
                    <MenuItemGroup>
                        <EnteMenuItem
                            label={ut(
                                "Create clusters   • internal only option",
                            )}
                            onClick={wipClusterDebug}
                        />
                    </MenuItemGroup>
                    <MenuSectionTitle
                        title={ut(
                            "Create and show in-memory clusters (not saved or synced). You can also view them in the search dropdown later.",
                        )}
                    />
                </Box>
            )}
        </Stack>
    );
};
