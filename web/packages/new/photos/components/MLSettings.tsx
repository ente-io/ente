import {
    canEnableML,
    disableML,
    enableML,
    getIsMLEnabledRemote,
    isMLEnabled,
    pauseML,
} from "@/new/photos/services/ml";
import { EnteDrawer } from "@/new/shared/components/EnteDrawer";
import { MenuItemGroup } from "@/new/shared/components/Menu";
import { Titlebar } from "@/new/shared/components/Titlebar";
import { pt, ut } from "@/next/i18n";
import log from "@/next/log";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import {
    Box,
    Button,
    Checkbox,
    type DialogProps,
    FormControlLabel,
    FormGroup,
    Link,
    Paper,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
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

    /**
     * The state of our component.
     *
     * To avoid confusion with useState, we call it status instead. */
    // TODO: This Status is not automatically synced with the lower layers that
    // hold the actual state.
    type Status =
        | "loading" /* fetching the data we need from the lower layers */
        | "notEligible" /* user is not in the beta program */
        | "disabled" /* eligible, but ML is currently disabled */
        | "enabled"; /* ML is enabled, but may be paused locally */

    const [status, setStatus] = useState<Status>("loading");
    const [openFaceConsent, setOpenFaceConsent] = useState(false);
    const [isEnabledLocal, setIsEnabledLocal] = useState(false);

    const refreshStatus = async () => {
        if (isMLEnabled() || (await getIsMLEnabledRemote())) {
            setStatus("enabled");
            setIsEnabledLocal(isMLEnabled());
        } else if (await canEnableML()) {
            setStatus("disabled");
        } else {
            setStatus("notEligible");
        }
    };

    useEffect(() => {
        void refreshStatus();
    }, []);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") handleRootClose();
        else onClose();
    };

    // The user may've changed the remote flag on a different device, so in both
    // cases (enable or resume), do the same flow:
    //
    // -   If remote flag is not set, then show the consent dialog
    // -   Otherwise enable ML (both locally and on remote).
    //
    const handleEnableOrResumeML = async () => {
        startLoading();
        try {
            if (!(await getIsMLEnabledRemote())) {
                setOpenFaceConsent(true);
            } else {
                await enableML();
                setStatus("enabled");
                setIsEnabledLocal(isMLEnabled());
            }
        } catch (e) {
            log.error("Failed to enable or resume ML", e);
            somethingWentWrong();
        } finally {
            finishLoading();
        }
    };

    const handleConsent = async () => {
        startLoading();
        try {
            await enableML();
            setStatus("enabled");
            setIsEnabledLocal(isMLEnabled());
            // Close the FaceConsent drawer, come back to ourselves.
            setOpenFaceConsent(false);
        } catch (e) {
            log.error("Failed to enable ML", e);
            somethingWentWrong();
        } finally {
            finishLoading();
        }
    };

    const handleToggleLocal = async () => {
        try {
            isMLEnabled() ? pauseML() : await handleEnableOrResumeML();
            setIsEnabledLocal(isMLEnabled());
        } catch (e) {
            log.error("Failed to toggle local state of ML", e);
            somethingWentWrong();
        }
    };

    const handleDisableML = async () => {
        startLoading();
        try {
            await disableML();
            setStatus("disabled");
        } catch (e) {
            log.error("Failed to disable ML", e);
            somethingWentWrong();
        } finally {
            finishLoading();
        }
    };

    const components: Record<Status, React.ReactNode> = {
        loading: <Loading />,
        notEligible: <ComingSoon />,
        disabled: <EnableML onEnable={handleEnableOrResumeML} />,
        enabled: (
            <ManageML
                {...{ isEnabledLocal, setDialogBoxAttributesV2 }}
                onToggleLocal={handleToggleLocal}
                onDisableML={handleDisableML}
            />
        ),
    };

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
                        title={pt("ML search")}
                        onRootClose={onRootClose}
                    />
                    {components[status]}
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

const ComingSoon: React.FC = () => {
    return (
        <Box px="8px">
            <Typography color="text.muted">
                {ut("We're putting finishing touches, coming back soon!")}
            </Typography>
        </Box>
    );
};

interface EnableMLProps {
    /** Called when the user enables ML. */
    onEnable: () => void;
}

const EnableML: React.FC<EnableMLProps> = ({ onEnable }) => {
    // TODO-ML: Update link.
    const moreDetails = () => openURL("https://ente.io/blog/desktop-ml-beta");

    return (
        <Stack py={"20px"} px={"16px"} spacing={"32px"}>
            <Typography color="text.muted">
                {pt(
                    "Enable ML (Machine Learning) for face recognition, magic search and other advanced search features",
                )}
            </Typography>
            <Stack spacing={"8px"}>
                <Button color={"accent"} size="large" onClick={onEnable}>
                    {t("ENABLE")}
                </Button>

                <Button color="secondary" size="large" onClick={moreDetails}>
                    {t("ML_MORE_DETAILS")}
                </Button>
            </Stack>
            <Typography color="text.faint" variant="small">
                {pt(
                    'Magic search allows to search photos by their contents (e.g. "car", "red car" or even "ferrari")',
                )}
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
                    title={t("ENABLE_FACE_SEARCH_TITLE")}
                    onRootClose={handleRootClose}
                />
                <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                    <Typography component="div" color="text.muted" px={"8px"}>
                        <Trans
                            i18nKey={"ENABLE_FACE_SEARCH_DESCRIPTION"}
                            components={{
                                a: (
                                    <Link
                                        target="_blank"
                                        href="https://ente.io/privacy#8-biometric-information-privacy-policy"
                                        underline="always"
                                        sx={{
                                            color: "inherit",
                                            textDecorationColor: "inherit",
                                        }}
                                    />
                                ),
                            }}
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
                            label={t("FACE_SEARCH_CONFIRMATION")}
                        />
                    </FormGroup>
                    <Stack px={"8px"} spacing={"8px"}>
                        <Button
                            color={"accent"}
                            size="large"
                            disabled={!acceptTerms}
                            onClick={onConsent}
                        >
                            {t("ENABLE_FACE_SEARCH")}
                        </Button>
                        <Button
                            color={"secondary"}
                            size="large"
                            onClick={onClose}
                        >
                            {t("CANCEL")}
                        </Button>
                    </Stack>
                </Stack>
            </Stack>
        </EnteDrawer>
    );
};

interface ManageMLProps {
    /** `true` if ML is enabled locally (in addition to remote). */
    isEnabledLocal: boolean;
    /** Called when the user wants to toggle the ML status locally. */
    onToggleLocal: () => void;
    /** Called when the user wants to disable ML. */
    onDisableML: () => void;
    /** Subset of appContext. */
    setDialogBoxAttributesV2: NewAppContextPhotos["setDialogBoxAttributesV2"];
}

const ManageML: React.FC<ManageMLProps> = ({
    isEnabledLocal,
    onToggleLocal,
    onDisableML,
    setDialogBoxAttributesV2,
}) => {
    const confirmDisableML = () => {
        setDialogBoxAttributesV2({
            title: pt("Disable ML search"),
            content: (
                <Typography>
                    {pt(
                        "Do you want to disable ML search on all your devices?",
                    )}
                </Typography>
            ),
            close: { text: t("CANCEL") },
            proceed: {
                variant: "critical",
                text: pt("Disable"),
                action: onDisableML,
            },
            buttonDirection: "row",
        });
    };

    // TODO-ML:
    // const [indexingStatus, setIndexingStatus] = useState<CLIPIndexingStatus>({
    //     indexed: 0,
    //     pending: 0,
    // });

    // useEffect(() => {
    //     clipService.setOnUpdateHandler(setIndexingStatus);
    //     clipService.getIndexingStatus().then((st) => setIndexingStatus(st));
    //     return () => clipService.setOnUpdateHandler(undefined);
    // }, []);
    /* TODO-ML: isElectron() && (
        <Box>
            <MenuSectionTitle
                title={t("MAGIC_SEARCH_STATUS")}
            />
            <Stack py={"12px"} px={"12px"} spacing={"24px"}>
                <VerticallyCenteredFlex
                    justifyContent="space-between"
                    alignItems={"center"}
                >
                    <Typography>
                        {t("INDEXED_ITEMS")}
                    </Typography>
                    <Typography>
                        {formatNumber(
                            indexingStatus.indexed,
                        )}
                    </Typography>
                </VerticallyCenteredFlex>
                <VerticallyCenteredFlex
                    justifyContent="space-between"
                    alignItems={"center"}
                >
                    <Typography>
                        {t("PENDING_ITEMS")}
                    </Typography>
                    <Typography>
                        {formatNumber(
                            indexingStatus.pending,
                        )}
                    </Typography>
                </VerticallyCenteredFlex>
            </Stack>
        </Box>
    )*/

    return (
        <Stack px={"16px"} py={"20px"} gap={4}>
            <Stack gap={3}>
                <MenuItemGroup>
                    <EnteMenuItem
                        label={pt("Enabled")}
                        variant="toggle"
                        checked={true}
                        onClick={confirmDisableML}
                    />
                </MenuItemGroup>
                <MenuItemGroup>
                    <EnteMenuItem
                        label={pt("On this device")}
                        variant="toggle"
                        checked={isEnabledLocal}
                        onClick={onToggleLocal}
                    />
                </MenuItemGroup>
            </Stack>
            <Paper variant="outlined">
                <Stack gap={4} px={2} py={2}>
                    <Stack direction="row" gap={2} justifyContent={"space-between"}>
                        <Typography color="text.muted">Status</Typography>
                        <Typography>Indexing</Typography>
                    </Stack>
                    <Stack direction="row" gap={2} justifyContent={"space-between"}>
                        <Typography color="text.muted">Processed</Typography>
                        <Typography textAlign="right">33,000,000 / 13,000,000</Typography>
                    </Stack>
                </Stack>
            </Paper>
        </Stack>
    );
};
