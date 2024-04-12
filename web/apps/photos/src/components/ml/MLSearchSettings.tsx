import log from "@/next/log";
import {
    Box,
    Button,
    Checkbox,
    DialogProps,
    FormControlLabel,
    FormGroup,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import {
    getFaceSearchEnabledStatus,
    updateFaceSearchEnabledStatus,
} from "services/userService";
import { openLink } from "utils/common";

export const MLSearchSettings = ({ open, onClose, onRootClose }) => {
    const {
        updateMlSearchEnabled,
        mlSearchEnabled,
        setDialogMessage,
        somethingWentWrong,
        startLoading,
        finishLoading,
    } = useContext(AppContext);

    const [enableFaceSearchView, setEnableFaceSearchView] = useState(false);

    const openEnableFaceSearch = () => {
        setEnableFaceSearchView(true);
    };
    const closeEnableFaceSearch = () => {
        setEnableFaceSearchView(false);
    };

    const enableMlSearch = async () => {
        try {
            const hasEnabledFaceSearch = await getFaceSearchEnabledStatus();
            if (!hasEnabledFaceSearch) {
                openEnableFaceSearch();
            } else {
                updateMlSearchEnabled(true);
            }
        } catch (e) {
            log.error("Enable ML search failed", e);
            somethingWentWrong();
        }
    };

    const enableFaceSearch = async () => {
        try {
            startLoading();
            await updateFaceSearchEnabledStatus(true);
            updateMlSearchEnabled(true);
            closeEnableFaceSearch();
            finishLoading();
        } catch (e) {
            log.error("Enable face search failed", e);
            somethingWentWrong();
        }
    };

    const disableMlSearch = async () => {
        try {
            await updateMlSearchEnabled(false);
            onClose();
        } catch (e) {
            log.error("Disable ML search failed", e);
            somethingWentWrong();
        }
    };

    const disableFaceSearch = async () => {
        try {
            startLoading();
            await updateFaceSearchEnabledStatus(false);
            await disableMlSearch();
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
                {mlSearchEnabled ? (
                    <ManageMLSearch
                        onClose={onClose}
                        disableMlSearch={disableMlSearch}
                        handleDisableFaceSearch={confirmDisableFaceSearch}
                        onRootClose={handleRootClose}
                    />
                ) : (
                    <EnableMLSearch
                        onClose={onClose}
                        enableMlSearch={enableMlSearch}
                        onRootClose={handleRootClose}
                    />
                )}
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

function EnableMLSearch({ onClose, enableMlSearch, onRootClose }) {
    const showDetails = () =>
        openLink("https://ente.io/blog/desktop-ml-beta", true);

    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ML_SEARCH")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    {" "}
                    <Typography color="text.muted">
                        <Trans i18nKey={"ENABLE_ML_SEARCH_DESCRIPTION"} />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button
                        color={"accent"}
                        size="large"
                        onClick={enableMlSearch}
                    >
                        {t("ENABLE")}
                    </Button>
                    <Button
                        color="secondary"
                        size="large"
                        onClick={showDetails}
                    >
                        {t("ML_MORE_DETAILS")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}

function ManageMLSearch({
    onClose,
    disableMlSearch,
    handleDisableFaceSearch,
    onRootClose,
}) {
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
