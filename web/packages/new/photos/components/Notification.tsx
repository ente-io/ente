/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { EllipsizedTypography } from "@/base/components/Typography";
import { FilledIconButton } from "@/base/components/mui";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { isSxArray } from "@/base/components/utils/sx";
import CloseIcon from "@mui/icons-material/Close";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    Button,
    Snackbar,
    Stack,
    type ButtonProps,
    type SxProps,
    type Theme,
} from "@mui/material";
import React from "react";

/**
 * Customize the contents of an {@link Notification}.
 */
export type NotificationAttributes =
    | MessageSubTextNotificationAttributes
    | TitleCaptionNotificationAttributes;

interface MessageSubTextNotificationAttributes {
    startIcon?: React.ReactNode;
    variant: ButtonProps["color"];
    message?: React.JSX.Element | string;
    subtext?: React.JSX.Element | string;
    title?: never;
    caption?: never;
    onClick: () => void;
    endIcon?: React.ReactNode;
}

interface TitleCaptionNotificationAttributes {
    startIcon?: React.ReactNode;
    variant: ButtonProps["color"];
    title?: React.JSX.Element | string;
    caption?: React.JSX.Element | string;
    message?: never;
    subtext?: never;
    onClick: () => void;
    endIcon?: React.ReactNode;
}

type NotificationProps = ModalVisibilityProps & {
    /**
     * Attributes that customize the contents of the notification, and the
     * actions that happen on clicking it.
     */
    attributes: NotificationAttributes;
    /**
     * If `true`, then the notification is not closed when it is clicked, and
     * should be closed by pressing the close icon button it contains.
     */
    keepOpenOnClick?: boolean;
    /**
     * Horizontal positioning of the notification.
     *
     * Default: "right".
     */
    horizontal?: "left" | "right";
    /**
     * Vertical positioning of the notification.
     *
     * Default: "bottom".
     */
    vertical?: "top" | "bottom";
    /**
     * sx props to customize the appearance of the underlying MUI
     * {@link Snackbar}.
     */
    sx?: SxProps<Theme>;
};

/**
 * A small notification popup shown on some edge of the screen to notify the
 * user of some asynchronous update or error.
 *
 * In Material UI terms, this is a custom "Snackbar".
 *
 * A single Notification component can be shared by multiple sources of
 * notifications (which means that there can't be multiple of them outstanding
 * at the same time from the same source). The source can customize the actual
 * contents and appearance of this notification by providing appropriate
 * {@link NotificationAttributes}.
 */
export const Notification: React.FC<NotificationProps> = ({
    open,
    onClose,
    horizontal,
    vertical,
    sx,
    attributes,
    keepOpenOnClick,
}) => {
    if (!attributes) return <></>;

    const handleClose: ButtonProps["onClick"] = (event) => {
        onClose();
        event.stopPropagation();
    };

    const handleClick = () => {
        attributes.onClick();
        if (!keepOpenOnClick) {
            onClose();
        }
    };

    return (
        <Snackbar
            open={open}
            anchorOrigin={{
                horizontal: horizontal ?? "right",
                vertical: vertical ?? "bottom",
            }}
            sx={[
                { width: "min(320px, 100vw)", bgcolor: "background.base" },
                ...(sx ? (isSxArray(sx) ? sx : [sx]) : []),
            ]}
        >
            <Button
                color={attributes.variant}
                onClick={handleClick}
                sx={(theme) => ({
                    textAlign: "left",
                    flex: "1",
                    padding: theme.spacing(1.5, 2),
                    borderRadius: "8px",
                })}
            >
                <Stack
                    spacing={2}
                    direction="row"
                    sx={{ flex: "1", alignItems: "center", width: "100%" }}
                >
                    <Box sx={{ svg: { fontSize: "36px" } }}>
                        {attributes.startIcon ?? <InfoIcon />}
                    </Box>

                    <Stack
                        direction={"column"}
                        spacing={0.5}
                        sx={{
                            flex: 1,
                            textAlign: "left",
                            // This is necessary to trigger the ellipsizing of the
                            // text in children.
                            overflow: "hidden",
                        }}
                    >
                        {attributes.subtext && (
                            <EllipsizedTypography variant="small">
                                {attributes.subtext}
                            </EllipsizedTypography>
                        )}
                        {attributes.message && (
                            <EllipsizedTypography sx={{ fontWeight: "medium" }}>
                                {attributes.message}
                            </EllipsizedTypography>
                        )}
                        {attributes.title && (
                            <EllipsizedTypography sx={{ fontWeight: "medium" }}>
                                {attributes.title}
                            </EllipsizedTypography>
                        )}
                        {attributes.caption && (
                            <EllipsizedTypography variant="small">
                                {attributes.caption}
                            </EllipsizedTypography>
                        )}
                    </Stack>

                    {attributes.endIcon ? (
                        <FilledIconButton
                            onClick={attributes.onClick}
                            sx={{ fontSize: "36px" }}
                        >
                            {attributes?.endIcon}
                        </FilledIconButton>
                    ) : (
                        <FilledIconButton onClick={handleClose}>
                            <CloseIcon />
                        </FilledIconButton>
                    )}
                </Stack>
            </Button>
        </Snackbar>
    );
};
