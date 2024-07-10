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
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import type { NewAppContextPhotos } from "../types/context";

interface MLSettingsProps {
    /** If `true`, then this drawer page is shown. */
    open: boolean;
    /** Called when the user wants to go back from this drawer page. */
    onClose: () => void;
    /** Called when the user wants to close the containing drawer. */
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
        setDialogMessage,
        somethingWentWrong,
        startLoading,
        finishLoading,
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
        | "enabled" /* ML is enabled */
        | "paused"; /* ML is disabled locally, but is otherwise enabled */

    const [status, setStatus] = useState<Status>("loading");

    const refreshStatus = async () => {
        if (isMLEnabled()) {
            setStatus("enabled");
        } else if (await getIsMLEnabledRemote()) {
            setStatus("paused");
        } else if (await canEnableML()) {
            setStatus("disabled");
        } else {
            setStatus("notEligible");
        }
    };

    useEffect(() => {
        void refreshStatus();
    }, []);

    const [openFaceConsent, setOpenFaceConsent] = useState(false);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") handleRootClose();
        else onClose();
    };

    const openEnableFaceSearch = () => {
        setEnableFaceSearchView(true);
    };
    const closeEnableFaceSearch = () => {
        setEnableFaceSearchView(false);
    };

    // The user may've changed the remote flag on a different device, so in both
    // cases (enable or resume), do the same flow:
    //
    // -   If remote flag is not set, then show the consent dialog
    // -   Otherwise enable ML (both locally and on remote).
    //
    const handleEnableOrResumeML = async () => {
        try {
            if (!(await getIsMLEnabledRemote())) {
                setOpenFaceConsent(true);
            } else {
                await enableML();
                setStatus("enabled");
            }
        } catch (e) {
            log.error("Failed to enable or resume ML", e);
            somethingWentWrong();
        }
    };

    const enableFaceSearch = async () => {
        try {
            startLoading();
            await enableML();
            closeEnableFaceSearch();
            finishLoading();
        } catch (e) {
            log.error("Enable face search failed", e);
            somethingWentWrong();
        }
    };

    const disableMlSearch = async () => {
        try {
            pauseML();
            onClose();
        } catch (e) {
            log.error("Disable ML search failed", e);
            somethingWentWrong();
        }
    };

    const disableFaceSearch = async () => {
        try {
            startLoading();
            await disableML();
            onClose();
            finishLoading();
        } catch (e) {
            log.error("Disable face search failed", e);
            somethingWentWrong();
        }
    };

    const confirmDisableFaceSearch = () => {
        setDialogMessage({
            title: t("DISABLE_FACE_SEARCH_TITLE"),
            content: (
                <Typography>
                    <Trans i18nKey={"DISABLE_FACE_SEARCH_DESCRIPTION"} />
                </Typography>
            ),
            close: { text: t("CANCEL") },
            proceed: {
                variant: "primary",
                text: t("DISABLE_FACE_SEARCH"),
                action: disableFaceSearch,
            },
        });
    };

    const components: Record<Status, React.ReactNode> = {
        loading: <Loading />,
        notEligible: <ComingSoon />,
        disabled: (
            <EnableML
                onClose={onClose}
                onEnable={handleEnableOrResumeML}
                onRootClose={handleRootClose}
            />
        ),
        enabled: (
            <ManageMLSearch
                onClose={onClose}
                disableMlSearch={disableMlSearch}
                handleDisableFaceSearch={confirmDisableFaceSearch}
                onRootClose={handleRootClose}
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
                    {components[status] ?? <Loading />}
                </Stack>
            </EnteDrawer>

            <EnableFaceSearch
                open={enableFaceSearchView}
                onClose={closeEnableFaceSearch}
                enableFaceSearch={enableFaceSearch}
                onRootClose={handleRootClose}
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
    // const showDetails = () =>
    //     openLink("https://ente.io/blog/desktop-ml-beta", true);

    return (
        <Stack py={"20px"} px={"8px"} spacing={"32px"}>
            (
            <Stack px={"8px"} spacing={"8px"}>
                <Button color={"accent"} size="large" onClick={onEnable}>
                    {t("ENABLE")}
                </Button>
                {/*
                        <Button
                        color="secondary"
                        size="large"
                        onClick={showDetails}
                        >
                            {t("ML_MORE_DETAILS")}
                        </Button>
                        */}
            </Stack>
            )
        </Stack>
    );
};

function EnableFaceSearch({ open, onClose, enableFaceSearch, onRootClose }) {
    const [acceptTerms, setAcceptTerms] = useState(false);

    useEffect(() => {
        setAcceptTerms(false);
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
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
                    <Typography color="text.muted" px={"8px"}>
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
                            onClick={enableFaceSearch}
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
}

function ManageMLSearch({
    onClose,
    disableMlSearch,
    handleDisableFaceSearch,
    onRootClose,
}) {
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
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ML_SEARCH")}
                onRootClose={onRootClose}
            />
            <Box px={"16px"}>
                <Stack py={"20px"} spacing={"24px"}>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={disableMlSearch}
                            label={t("DISABLE_BETA")}
                        />
                    </MenuItemGroup>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={handleDisableFaceSearch}
                            label={t("DISABLE_FACE_SEARCH")}
                        />
                    </MenuItemGroup>
                </Stack>
            </Box>
        </Stack>
    );
}
