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
    Stack,
    Typography,
    type DialogProps,
} from "@mui/material";
import { t } from "i18next";
import React, { useState } from "react";

/**
 * Customize the properties of the dialog box.
 *
 * Our custom dialog box helpers are meant for small message boxes, usually
 * meant to confirm some user action. If more customization is needed, it might
 * be a better idea to reach out for a bespoke MUI {@link DialogBox} instead.
 */
export interface MiniDialogAttributes {
    icon?: React.ReactNode;
    /**
     * The dialog's title
     *
     * Usually this will be a string, but it can be any {@link ReactNode}. Note
     * that it always gets wrapped in a Typography element to set the font
     * style, so if your ReactNode wants to do its own thing, it'll need to
     * reset or override these customizations.
     */
    title?: React.ReactNode;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    /**
     * The dialog's content.
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
    secondary?: {
        text: string;
        action: () => void;
        variant?: ButtonProps["color"];
        disabled?: boolean;
    };
    buttons?: {
        text: string;
        action: () => void;
        variant: ButtonProps["color"];
        disabled?: boolean;
    }[];
    buttonDirection?: "row" | "column";
}

type MiniDialogProps = React.PropsWithChildren<
    Omit<DialogProps, "onClose"> & {
        onClose: () => void;
        attributes?: MiniDialogAttributes;
    }
>;

/**
 * A small, mostly predefined, MUI {@link Dialog} that can be used to notify the
 * user, or ask for confirmation before actions.
 *
 * The rendered dialog can be customized by modifying the {@link attributes}
 * prop. If you find yourself wanting to customize it further, consider just
 * creating a new bespoke instantiation of a {@link Dialog}.
 */
export function MiniDialog({
    attributes,
    children,
    open,
    onClose,
    ...props
}: MiniDialogProps) {
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
                {(attributes.proceed ||
                    attributes.close ||
                    attributes.buttons?.length) && (
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
                        {attributes.buttons &&
                            attributes.buttons.map((b) => (
                                <FocusVisibleButton
                                    size="large"
                                    key={b.text}
                                    color={b.variant}
                                    onClick={() => {
                                        b.action();
                                        onClose();
                                    }}
                                    disabled={b.disabled}
                                >
                                    {b.text}
                                </FocusVisibleButton>
                            ))}
                    </Stack>
                )}
            </Stack>
        </Dialog>
    );
}

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

/**
 * TODO This is a duplicate of MiniDialog. This is for use by call sites that
 * were using the MiniDialog not as a dialog but as a base container. Such use
 * cases are better served by directly using the MUI {@link Dialog}, so these
 * are considered deprecated. Splitting these here so that we can streamline the
 * API for the notify/confirm case separately.
 */
export function DialogBoxV2({
    attributes,
    children,
    open,
    onClose,
    ...props
}: MiniDialogProps) {
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
                {(attributes.proceed ||
                    attributes.close ||
                    attributes.buttons?.length) && (
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
                        {attributes.buttons &&
                            attributes.buttons.map((b) => (
                                <FocusVisibleButton
                                    size="large"
                                    key={b.text}
                                    color={b.variant}
                                    onClick={() => {
                                        b.action();
                                        onClose();
                                    }}
                                    disabled={b.disabled}
                                >
                                    {b.text}
                                </FocusVisibleButton>
                            ))}
                    </Stack>
                )}
            </Stack>
        </Dialog>
    );
}
