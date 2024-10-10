// TODO:
/* eslint-disable @typescript-eslint/prefer-optional-chain */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
/* eslint-disable @typescript-eslint/prefer-nullish-coalescing */
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import { dialogCloseHandler } from "@ente/shared/components/DialogBox/TitleWithCloseButton";
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
     * Customize the primary action button offered by the dialog box.
     *
     * This is provided by boxes which serve as some sort of confirmation. For
     * dialogs which are informational notifications, this is usually skipped,
     * only the {@link close} action button is configured.
     */
    proceed?: {
        /** The string to use as the label for the primary action button. */
        text: string;
        /** The color of the button. */
        variant?: ButtonProps["color"];
        /**
         * The function to call when the user presses the primary action button.
         *
         * It is passed a {@link setLoading} function that can be used to show
         * or hide loading indicator or the primary action button.
         */
        action:
            | (() => void | Promise<void>)
            | ((setLoading: (value: boolean) => void) => void | Promise<void>);
    };
    /**
     * Customize the cancel (dismiss) action button offered by the dialog box.
     *
     * Usually all dialog boxes should have a cancel action.
     */
    close?: {
        /** The string to use as the label for the cancel button. */
        text?: string;
        /** The color of the button. */
        variant?: ButtonProps["color"];
        /**
         * The function to call when the user cancels.
         *
         * If provided, this callback is invoked before closing the dialog.
         */
        action?: () => void;
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
    const [loading, setLoading] = useState(false);

    if (!attributes) {
        return <></>;
    }

    const handleClose = dialogCloseHandler({
        staticBackdrop: attributes.staticBackdrop,
        nonClosable: attributes.nonClosable,
        onClose: onClose,
    });

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
            {(attributes.icon || attributes.title) && (
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
                {(attributes.proceed || attributes.close) && (
                    <Stack
                        sx={{
                            paddingBlockStart: "24px",
                            gap: "12px",
                        }}
                        direction={
                            attributes.buttonDirection == "row"
                                ? "row-reverse"
                                : "column"
                        }
                    >
                        {attributes.proceed && (
                            <LoadingButton
                                loading={loading}
                                fullWidth
                                color={attributes.proceed?.variant}
                                onClick={async () => {
                                    await attributes.proceed?.action(
                                        setLoading,
                                    );

                                    onClose();
                                }}
                            >
                                {attributes.proceed.text}
                            </LoadingButton>
                        )}
                        {attributes.close && (
                            <FocusVisibleButton
                                fullWidth
                                color={attributes.close?.variant ?? "secondary"}
                                onClick={() => {
                                    attributes.close?.action &&
                                        attributes.close?.action();
                                    onClose();
                                }}
                            >
                                {attributes.close?.text ?? t("ok")}
                            </FocusVisibleButton>
                        )}
                    </Stack>
                )}
            </DialogContent>
        </Dialog>
    );
};

// TODO: Sketch of a possible approach to using this. Haven't throught this
// through, just noting down the outline inspired by an API I saw.
// /**
//  * A React hook for simplifying use of MiniDialog within the photos app context.
//  *
//  * It relies on the presence of the {@link setDialogBoxAttributesV2} function
//  * provided by the Photos app's {@link AppContext}.
//  */
// export const useConfirm = (attr) => {
//     const {setDialogBoxAttributesV2} = useAppContext();
//     return () => {
//         new Promise((resolve) => {
//         setDialogBoxAttributesV2(
//             proceed: {
//                 action: attr.action.then(resolve)
//             }
//         )
//     }
// }

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
