import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import type { ButtonProps } from "@mui/material";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Stack,
    Typography,
    type DialogProps,
} from "@mui/material";
import { t } from "i18next";
import React, { useState } from "react";
import log from "../log";

/**
 * Customize the contents of an {@link AttributedMiniDialog}.
 */
export interface MiniDialogAttributes {
    /**
     * The dialog's title.
     *
     * This will be usually be a string, but the prop accepts any React node to
     * allow passing a i18next <Trans /> component.
     */
    title?: React.ReactNode;
    /**
     * An optional component shown next to the title.
     */
    icon?: React.ReactNode;
    /**
     * The dialog's message.
     *
     * This will be usually be a string, but the prop accepts any React node to
     * allow passing a i18next <Trans /> component.
     */
    message?: React.ReactNode;
    /**
     * If `true`, then the dialog cannot be closed (e.g. with the ESC key, or
     * clicking on the backdrop) except through one of the explicitly provided
     * actions.
     */
    nonClosable?: boolean;
    /**
     * Customize the primary action button shown in the dialog.
     *
     * This is provided by boxes which serve as some sort of confirmation. For
     * dialogs which are informational notifications, this is usually skipped,
     * only the {@link close} action button is configured.
     */
    continue?: {
        /**
         * The string to use as the label for the primary action button.
         *
         * Default is `t("ok")`.
         */
        text?: string;
        /**
         * The color of the button.
         *
         * Default is "accent".
         */
        color?: ButtonProps["color"];
        /**
         * If `true`, the primary action button is auto focused when the dialog
         * is opened, allowing the user to confirm just by pressing ENTER.
         */
        autoFocus?: ButtonProps["autoFocus"];
        /**
         * The function to call when the user activates the button.
         *
         * If this function returns a promise, then an activity indicator will
         * be shown on the button until the promise settles.
         *
         * If this function is not provided, or if the function completes /
         * fullfills, then then the dialog is automatically closed.
         *
         * Otherwise (that is, if the provided function throws), the dialog
         * remains open, showing a generic error.
         *
         * That's quite a mouthful, here's a flowchart:
         *
         * - Not provided: Close
         * - Provided sync:
         *   - Success: Close
         *   - Failure: Remain open, showing generic error
         * - Provided async:
         *   - Success: Close
         *   - Failure: Remain open, showing generic error
         */
        action?: () => void | Promise<void>;
    };
    /**
     * The string to use as the label for the cancel button.
     *
     * Default is `t("cancel")`.
     *
     * Set this to `false` to omit the cancel button altogether.
     *
     * The object form allows providing both the button title and the action
     * handler (synchronous). The dialog is always closed on clicks.
     */
    cancel?:
        | string
        | false
        | {
              text: string;
              action: () => void;
          };
    /** The direction in which the buttons are stacked. Default is "column". */
    buttonDirection?: "row" | "column";
}

type MiniDialogProps = Omit<DialogProps, "onClose"> & {
    onClose: () => void;
    attributes?: MiniDialogAttributes;
};

/**
 * A small, mostly predefined, MUI {@link Dialog} that can be used to notify the
 * user, or ask for confirmation before actions.
 *
 * The rendered dialog can be customized by modifying the {@link attributes}
 * prop. If you find yourself wanting to customize it further, consider either
 * using a {@link TitledMiniDialog} or {@link Dialog}.
 */
export const AttributedMiniDialog: React.FC<
    React.PropsWithChildren<MiniDialogProps>
> = ({ open, onClose, attributes, children, ...props }) => {
    const [phase, setPhase] = useState<"loading" | "failed" | undefined>();

    if (!attributes) {
        return <></>;
    }

    const resetPhaseAndClose = () => {
        setPhase(undefined);
        onClose();
    };

    const handleClose = () => {
        if (attributes.nonClosable) return;
        resetPhaseAndClose();
    };

    const [cancelTitle, handleCancel] = ((
        c: MiniDialogAttributes["cancel"],
    ) => {
        if (c === false) return [undefined, undefined];
        if (c === undefined) return [t("cancel"), resetPhaseAndClose];
        if (typeof c == "string") return [c, resetPhaseAndClose];
        return [
            c.text,
            () => {
                resetPhaseAndClose();
                c.action();
            },
        ];
    })(attributes.cancel);

    const { PaperProps, ...rest } = props;

    return (
        <Dialog
            open={open}
            fullWidth
            PaperProps={{
                ...PaperProps,
                sx: {
                    maxWidth: "360px",
                    ...PaperProps?.sx,
                },
            }}
            onClose={handleClose}
            {...rest}
        >
            {(attributes.icon ?? attributes.title) ? (
                <Box
                    sx={{
                        display: "flex",
                        justifyContent: "space-between",
                        "& > svg": {
                            fontSize: "32px",
                            color: "text.faint",
                        },
                        padding: "24px 16px 16px 16px",
                    }}
                >
                    {attributes.title && (
                        <DialogTitle sx={{ "&&&": { padding: 0 } }}>
                            {attributes.title}
                        </DialogTitle>
                    )}
                    {attributes.icon}
                </Box>
            ) : (
                <Box sx={{ height: "8px" }} /> /* Spacer */
            )}
            <DialogContent>
                {attributes.message && (
                    <Typography
                        component={
                            typeof attributes.message == "string" ? "p" : "div"
                        }
                        color="text.muted"
                    >
                        {attributes.message}
                    </Typography>
                )}
                {children}
                <Stack
                    sx={{ paddingBlockStart: "24px", gap: "12px" }}
                    direction={attributes.buttonDirection ?? "column"}
                >
                    {phase == "failed" && (
                        <Typography variant="small" color="critical.main">
                            {t("generic_error")}
                        </Typography>
                    )}
                    {attributes.continue && (
                        <LoadingButton
                            loading={phase == "loading"}
                            fullWidth
                            color={attributes.continue.color ?? "accent"}
                            autoFocus={attributes.continue.autoFocus}
                            onClick={async () => {
                                setPhase("loading");
                                try {
                                    await attributes.continue?.action?.();
                                    resetPhaseAndClose();
                                } catch (e) {
                                    log.error("Error", e);
                                    setPhase("failed");
                                }
                            }}
                        >
                            {attributes.continue.text ?? t("ok")}
                        </LoadingButton>
                    )}
                    {cancelTitle && (
                        <FocusVisibleButton
                            fullWidth
                            color="secondary"
                            onClick={handleCancel}
                        >
                            {cancelTitle}
                        </FocusVisibleButton>
                    )}
                </Stack>
            </DialogContent>
        </Dialog>
    );
};

type TitledMiniDialogProps = Omit<DialogProps, "onClose"> & {
    onClose: () => void;
    /**
     * The dialog's title.
     */
    title?: React.ReactNode;
};

/**
 * MiniDialog in a "shell" form.
 *
 * This is a {@link Dialog} for use at places which need more customization than
 * what {@link AttributedMiniDialog} provides, but wish to retain a similar look
 * and feel without duplicating code.
 *
 * It does three things:
 *
 * - Sets a fixed size and padding similar to {@link AttributedMiniDialog}.
 * - Takes the title as a prop, and wraps it in a {@link DialogTitle}.
 * - Wraps children in a scrollable {@link DialogContent}.
 */
export const TitledMiniDialog: React.FC<
    React.PropsWithChildren<TitledMiniDialogProps>
> = ({ open, onClose, title, children, ...props }) => {
    const { PaperProps, ...rest } = props;

    return (
        <Dialog
            open={open}
            onClose={onClose}
            fullWidth
            PaperProps={{
                ...PaperProps,
                sx: {
                    maxWidth: "360px",
                    ...PaperProps?.sx,
                },
            }}
            {...rest}
        >
            <DialogTitle sx={{ "&&&": { paddingBlock: "24px 16px" } }}>
                {title}
            </DialogTitle>
            <DialogContent>{children}</DialogContent>
        </Dialog>
    );
};
