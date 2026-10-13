import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    Stack,
    Typography,
} from "@mui/material";
import { InlineErrorIndicator } from "ente-base/components/ErrorIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import log from "ente-base/log";
import { t } from "i18next";
import { useId, useState } from "react";

type TrashFilesDialogProps = ModalVisibilityProps & {
    count: number;
    onConfirm: () => void | Promise<void>;
};

export const TrashFilesDialog: React.FC<TrashFilesDialogProps> = ({
    open,
    onClose,
    count,
    onConfirm,
}) => {
    const [phase, setPhase] = useState<"loading" | "failed" | undefined>();
    const titleID = useId();
    const messageID = useId();

    const resetAndClose = () => {
        setPhase(undefined);
        onClose();
    };

    const handleClose = () => {
        if (phase !== "loading") resetAndClose();
    };

    const handleConfirm = async () => {
        setPhase("loading");
        try {
            await onConfirm();
            resetAndClose();
        } catch (e) {
            log.error(e);
            setPhase("failed");
        }
    };

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            aria-labelledby={titleID}
            aria-describedby={messageID}
            fullWidth
            slotProps={{
                paper: {
                    sx: {
                        maxWidth: "440px",
                        borderRadius: "24px",
                        position: "relative",
                        textAlign: "center",
                        "& .MuiButton-root": {
                            fontWeight: 500,
                            minHeight: "48px",
                            padding: "14px 24px",
                            borderRadius: "20px",
                        },
                    },
                },
            }}
        >
            <IconButton
                aria-label={t("close")}
                disabled={phase === "loading"}
                onClick={handleClose}
                sx={{
                    position: "absolute",
                    top: 16,
                    right: 16,
                    width: 36,
                    height: 36,
                    backgroundColor: "fill.faint",
                }}
            >
                <CloseIcon sx={{ fontSize: 20 }} />
            </IconButton>
            <Stack sx={{ alignItems: "center", pt: "38px", px: 3.5 }}>
                <Box
                    component="img"
                    src="/images/warning-red.png"
                    alt=""
                    sx={{ width: 68, height: 64, objectFit: "contain" }}
                />
                <DialogTitle
                    id={titleID}
                    sx={{ "&&&": { p: 0, mt: 3 }, fontSize: 20 }}
                >
                    {t("trash_items_title", {
                        count,
                        fallbackLng: false,
                        defaultValue: t(
                            count === 1
                                ? "trash_file_title"
                                : "trash_files_title",
                        ),
                    })}
                </DialogTitle>
            </Stack>
            <DialogContent sx={{ padding: "16px 28px 24px" }}>
                <Typography id={messageID} sx={{ color: "text.muted" }}>
                    {t("trash_items_message", {
                        count,
                        fallbackLng: false,
                        defaultValue: t(
                            count === 1
                                ? "trash_file_message"
                                : "trash_files_message",
                        ),
                    })}
                </Typography>
                <Stack sx={{ pt: 3, gap: 1 }}>
                    {phase === "failed" && <InlineErrorIndicator />}
                    <LoadingButton
                        loading={phase === "loading"}
                        fullWidth
                        color="critical"
                        onClick={handleConfirm}
                    >
                        {t("move_to_trash")}
                    </LoadingButton>
                    <FocusVisibleButton
                        fullWidth
                        color="secondary"
                        disabled={phase === "loading"}
                        onClick={handleClose}
                    >
                        {t("cancel")}
                    </FocusVisibleButton>
                </Stack>
            </DialogContent>
        </Dialog>
    );
};
