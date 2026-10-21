import { publishCastPayload, revokeAllCastTokens } from "@/services/cast";
import { loadCast } from "@/utils/chromecast-sender";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CastIcon from "@mui/icons-material/Cast";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import CloseIcon from "@mui/icons-material/Close";
import KeyboardOutlinedIcon from "@mui/icons-material/KeyboardOutlined";
import {
    Box,
    Dialog,
    IconButton,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    v2CloseButtonSx,
    v2HeaderRowSx,
    v2PaperSx,
    v2TitleSx,
} from "ente-base/components/SingleInput.styles";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { isNamedError } from "ente-base/error";
import { ut } from "ente-base/i18n";
import log from "ente-base/log";
import type { Collection } from "ente-media/collection";
import { FocusVisibleUnstyledButton } from "ente-new/photos/components/UnstyledButton";
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { t } from "i18next";
import React, { useCallback, useEffect, useId, useState } from "react";
import { Trans } from "react-i18next";
import { z } from "zod";

type AlbumCastDialogProps = ModalVisibilityProps & { collection: Collection };

export const AlbumCastDialog: React.FC<AlbumCastDialogProps> = ({
    open,
    onClose,
    collection,
}) => {
    const titleID = useId();
    return (
        <Dialog
            {...{ open, onClose }}
            maxWidth={false}
            aria-labelledby={titleID}
            slotProps={{ paper: { sx: v2PaperSx } }}
        >
            <Stack sx={{ p: "24px", gap: "24px" }}>
                <Stack sx={{ gap: "16px" }}>
                    <Stack direction="row" sx={v2HeaderRowSx}>
                        <Typography
                            id={titleID}
                            component="h2"
                            sx={{
                                ...v2TitleSx,
                                fontFamily: "'Outfit Variable', sans-serif",
                            }}
                        >
                            {t("cast_album_to_tv")}
                        </Typography>
                        <IconButton
                            aria-label={t("close")}
                            onClick={onClose}
                            sx={v2CloseButtonSx}
                        >
                            <CloseIcon sx={{ fontSize: 18 }} />
                        </IconButton>
                    </Stack>
                </Stack>
                <AlbumCastDialogContents {...{ open, onClose, collection }} />
            </Stack>
        </Dialog>
    );
};

// MUI preserves a dialog child's state while hidden.
// Keep contents separate so each open starts fresh and reruns effects.
const AlbumCastDialogContents: React.FC<AlbumCastDialogProps> = ({
    open,
    onClose,
    collection,
}) => {
    const { castURL } = useSettingsSnapshot();

    const [view, setView] = useState<
        "choose" | "auto" | "pin" | "auto-cast-error"
    >("choose");

    const [browserCanCast, setBrowserCanCast] = useState(false);

    const castHost = new URL(castURL).host;

    useEffect(() => {
        setBrowserCanCast(typeof window.chrome != "undefined");
    }, []);

    const onSubmit: SingleInputFormProps["onSubmit"] = useCallback(
        async (value, setFieldError) => {
            try {
                await publishCastPayload(value.trim(), collection);
                onClose();
            } catch (e) {
                log.error("Failed to cast", e);
                if (isNamedError(e, "cast_device_not_found")) {
                    setFieldError(t("tv_not_found"));
                } else {
                    throw e;
                }
            }
        },
        [onClose, collection],
    );

    useEffect(() => {
        if (view == "auto") {
            void loadCast().then(async (cast) => {
                const instance = cast.framework.CastContext.getInstance();
                try {
                    await instance.requestSession();
                } catch (e) {
                    setView("auto-cast-error");
                    log.error("Error requesting session", e);
                    return;
                }
                const session = instance.getCurrentSession()!;
                session.addMessageListener(
                    "urn:x-cast:pair-request",
                    (_, message) => {
                        const { code } = CastPairRequest.parse(
                            JSON.parse(message),
                        );

                        void publishCastPayload(code, collection)
                            .then(() => {
                                setView("choose");
                                onClose();
                            })
                            .catch((e: unknown) => {
                                log.error("Error casting to TV", e);
                                setView("auto-cast-error");
                            });
                    },
                );

                const collectionID = collection.id;
                void session
                    .sendMessage("urn:x-cast:pair-request", { collectionID })
                    .then(() => {
                        log.debug(() => "urn:x-cast:pair-request sent");
                    });
            });
        }
    }, [onClose, view, collection]);

    useEffect(() => {
        // Start every open with new server-side sessions.
        // Revocation cannot affect this client, so do not block on it.
        if (open) void revokeAllCastTokens();
    }, [open]);

    return (
        <>
            {view == "choose" && (
                <Stack sx={{ gap: "12px" }}>
                    {browserCanCast && (
                        <PairingOption
                            icon={<CastIcon sx={{ fontSize: 24 }} />}
                            title={t("cast_auto_pair")}
                            description={t("cast_auto_pair_description")}
                            onClick={() => setView("auto")}
                        />
                    )}
                    <PairingOption
                        icon={<KeyboardOutlinedIcon sx={{ fontSize: 24 }} />}
                        title={t("pair_with_pin")}
                        description={t("pair_with_pin_description")}
                        onClick={() => setView("pin")}
                    />
                </Stack>
            )}
            {view == "auto" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <div>
                        <ActivityIndicator />
                    </div>
                    <Typography>{t("choose_device_from_browser")}</Typography>
                    <FocusVisibleButton
                        color="secondary"
                        onClick={() => setView("choose")}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                </Stack>
            )}
            {view == "auto-cast-error" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <Typography>{t("cast_auto_pair_failed")}</Typography>
                    <FocusVisibleButton
                        color="secondary"
                        onClick={() => setView("choose")}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                </Stack>
            )}
            {view == "pin" && (
                <Stack sx={{ gap: "20px" }}>
                    <FocusVisibleButton
                        variant="text"
                        color="secondary"
                        startIcon={<ArrowBackIcon />}
                        onClick={() => setView("choose")}
                        sx={{ alignSelf: "flex-start", p: 0 }}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                    <Stack sx={{ gap: 2 }}>
                        <Typography sx={{ color: "text.muted" }}>
                            <Trans
                                i18nKey="visit_cast_url"
                                components={{
                                    a: (
                                        <Link
                                            target="_blank"
                                            rel="noopener"
                                            href={castURL}
                                        />
                                    ),
                                }}
                                values={{ url: castHost }}
                            />
                        </Typography>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("enter_cast_pin_code")}
                        </Typography>
                    </Stack>
                    <SingleInputForm
                        label={t("code")}
                        placeholder={ut("123456")}
                        submitButtonTitle={t("pair_device_to_tv")}
                        onSubmit={onSubmit}
                    />
                </Stack>
            )}
        </>
    );
};

const CastPairRequest = z.object({ code: z.string() });

const PairingOption: React.FC<{
    icon: React.ReactNode;
    title: string;
    description: string;
    onClick: () => void;
}> = ({ icon, title, description, onClick }) => (
    <FocusVisibleUnstyledButton
        onClick={onClick}
        sx={(theme) => ({
            display: "flex",
            alignItems: "center",
            gap: "14px",
            width: "100%",
            boxSizing: "border-box",
            p: "18px 14px",
            borderRadius: "16px",
            textAlign: "left",
            color: "text.base",
            backgroundColor: "background.paper",
            "&:hover": { backgroundColor: "fill.faintHover" },
            ...theme.applyStyles("dark", { backgroundColor: "#282828" }),
        })}
    >
        <Box
            sx={{
                width: 36,
                height: 36,
                flexShrink: 0,
                display: "grid",
                placeItems: "center",
            }}
        >
            {icon}
        </Box>
        <Stack sx={{ flex: 1, minWidth: 0, gap: "4px" }}>
            <Typography sx={{ fontSize: 14, fontWeight: 500 }}>
                {title}
            </Typography>
            <Typography
                sx={{ fontSize: 12, lineHeight: "18px", color: "text.muted" }}
            >
                {description}
            </Typography>
        </Stack>
        <ChevronRightIcon
            sx={{ fontSize: 18, color: "text.muted", flexShrink: 0 }}
        />
    </FocusVisibleUnstyledButton>
);
