import { InlineErrorIndicator } from "@/base/components/ErrorIndicator";
import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import log from "@/base/log";
import { Stack, Typography, type ModalProps } from "@mui/material";
import { t } from "i18next";
import { useState } from "react";

type ConfirmDeleteFileDialogProps = ModalVisibilityProps & {
    /**
     * Called when the user confirms the deletion.
     *
     * The delete button will show an activity indicator until this async
     * operation completes.
     */
    onConfirm: () => Promise<void>;
};

/**
 * A bespoke variant of AttributedMiniDialog for use by the delete file
 * confirmation prompt that we show in the image viewer.
 *
 * - It auto focuses the primary action.
 * - It uses a lighter backdrop in light mode.
 */
export const ConfirmDeleteFileDialog: React.FC<
    ConfirmDeleteFileDialogProps
> = ({ open, onClose, onConfirm }) => {
    const [phase, setPhase] = useState<"loading" | "failed" | undefined>();

    const resetPhaseAndClose = () => {
        setPhase(undefined);
        onClose();
    };

    const handleClick = async () => {
        setPhase("loading");
        try {
            await onConfirm();
            resetPhaseAndClose();
        } catch (e) {
            log.error(e);
            setPhase("failed");
        }
    };

    const handleClose: ModalProps["onClose"] = (_, reason) => {
        // Ignore backdrop clicks when we're processing the user request.
        if (reason == "backdropClick" && phase == "loading") return;
        resetPhaseAndClose();
    };

    return (
        <TitledMiniDialog
            open={open}
            onClose={handleClose}
            title={t("trash_file_title")}
            sx={(theme) => ({
                // See: [Note: Lighter backdrop for overlays on photo viewer]
                ...theme.applyStyles("light", {
                    ".MuiBackdrop-root": {
                        backgroundColor: theme.vars.palette.backdrop.faint,
                    },
                }),
            })}
        >
            <Typography sx={{ color: "text.muted" }}>
                {t("trash_file_message")}
            </Typography>
            <Stack sx={{ pt: 3, gap: 1 }}>
                {phase == "failed" && <InlineErrorIndicator />}
                <LoadingButton
                    loading={phase == "loading"}
                    fullWidth
                    color="critical"
                    autoFocus
                    onClick={handleClick}
                >
                    {t("move_to_trash")}
                </LoadingButton>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    disabled={phase == "loading"}
                    onClick={resetPhaseAndClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </TitledMiniDialog>
    );
};
