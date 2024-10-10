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
     * An optional icon shown above the title.
     */
    icon?: React.ReactNode;
    /**
     * The dialog's title.
     *
     * While optional, it is usually provided. It will almost always be a
     * string, but the prop accepts any React node to allow passing a i18next
     * <Trans /> component.
     */
    title?: React.ReactNode;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    /**
     * The dialog's message.
     *
     * Similar to {@link title}, this is usually provided, and a string.
     */
    content?: React.ReactNode;
    /**
     * Customize the cancel (dismiss) action button offered by the dialog box.
     *
     * Usually dialog boxes should have a cancel action, but this can be skipped
     * to only show one of the other types of buttons.
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
    /**
     * Customize the primary action button offered by the dialog box.
     */
    proceed?: {
        /** The string to use as the label for the primary action. */
        text: string;
        /**
         * The function to call when the user presses the primary action button.
         *
         * It is passed a {@link setLoading} function that can be used to show
         * or hide loading indicator or the primary action button.
         */
        action:
            | (() => void | Promise<void>)
            | ((setLoading: (value: boolean) => void) => void | Promise<void>);
        variant?: ButtonProps["color"];
        disabled?: boolean;
    };
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
                    padding: "8px 12px",
                    maxWidth: "360px",
                    ...PaperProps?.sx,
                },
            }}
            {...rest}
        >
            <Stack spacing={"36px"} p={"16px"}>
                <Stack spacing={"19px"}>
                    {attributes.icon && (
                        <Box
                            sx={{
                                "& > svg": {
                                    fontSize: "32px",
                                },
                            }}
                        >
                            {attributes.icon}
                        </Box>
                    )}
                    {attributes.title && (
                        <Typography variant="large" fontWeight={"bold"}>
                            {attributes.title}
                        </Typography>
                    )}
                    {children ||
                        (attributes?.content && (
                            <Typography color="text.muted">
                                {attributes.content}
                            </Typography>
                        ))}
                </Stack>
                {(attributes.proceed || attributes.close) && (
                    <Stack
                        spacing={"8px"}
                        direction={
                            attributes.buttonDirection === "row"
                                ? "row-reverse"
                                : "column"
                        }
                        flex={1}
                    >
                        {attributes.proceed && (
                            <LoadingButton
                                loading={loading}
                                size="large"
                                color={attributes.proceed?.variant}
                                onClick={async () => {
                                    await attributes.proceed?.action(
                                        setLoading,
                                    );

                                    onClose();
                                }}
                                disabled={attributes.proceed.disabled}
                            >
                                {attributes.proceed.text}
                            </LoadingButton>
                        )}
                        {attributes.close && (
                            <FocusVisibleButton
                                size="large"
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
            </Stack>
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
