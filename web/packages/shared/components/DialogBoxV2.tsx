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
export interface DialogBoxAttributesV2 {
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

type IProps = React.PropsWithChildren<
    Omit<DialogProps, "onClose"> & {
        onClose: () => void;
        attributes?: DialogBoxAttributesV2;
    }
>;

export default function DialogBoxV2({
    attributes,
    children,
    open,
    onClose,
    ...props
}: IProps) {
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
