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
     * If `true`, then clicks in the backdrop are ignored. The default behaviour
     * is to close the dialog when the background is clicked.
     */
    staticBackdrop?: boolean;
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
        autoFocus?: boolean;
        /**
         * If `true`, close the dialog after {@link action} completes.
         * TODO: Test/Impl/Is this needed?
         */
        autoClose?: boolean;
        /**
         * The function to call when the user activates the button.
         *
         * Default is to close the dialog.
         *
         * It is passed a {@link setLoading} function that can be used to show
         * or hide loading indicator or the primary action button.
         */
        action?:
            | (() => void | Promise<void>)
            | ((setLoading: (value: boolean) => void) => void | Promise<void>);
    };
    /**
     * The string to use as the label for the cancel button.
     *
     * Default is `t("cancel")`.
     *
     * Set this to `false` to omit the cancel button altogether.
     */
    cancel?: string | false;
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
    const [loading, setLoading] = useState(false);

    if (!attributes) {
        return <></>;
    }

    const handleClose = () => {
        if (attributes.nonClosable) return;
        onClose();
    };

    const { PaperProps, ...rest } = props;

    return (
        <Dialog
            open={open}
            onClose={handleClose}
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
            {(attributes.icon ?? attributes.title) && (
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
            )}
            <DialogContent>
                {attributes.message && (
                    <Typography color="text.muted">
                        {attributes.message}
                    </Typography>
                )}
                {children}
                <Stack
                    sx={{ paddingBlockStart: "24px", gap: "12px" }}
                    direction={
                        attributes.buttonDirection == "row"
                            ? "row-reverse"
                            : "column"
                    }
                >
                    {attributes.continue && (
                        <LoadingButton
                            loading={loading}
                            fullWidth
                            color={attributes.continue.color ?? "accent"}
                            autoFocus={attributes.continue.autoFocus}
                            onClick={async () => {
                                await attributes.continue?.action?.(setLoading);
                                onClose();
                            }}
                        >
                            {attributes.continue.text ?? t("ok")}
                        </LoadingButton>
                    )}
                    {attributes.cancel && (
                        <FocusVisibleButton
                            fullWidth
                            color="secondary"
                            onClick={onClose}
                        >
                            {attributes.cancel ?? t("cancel")}
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
