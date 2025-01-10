/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { EllipsizedTypography } from "@/base/components/Typography";
import { RippleDisabledButton } from "@/base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { isSxArray } from "@/base/components/utils/sx";
import CloseIcon from "@mui/icons-material/Close";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    IconButton,
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
export interface NotificationAttributes {
    type: "messageSubText" | "titleCaption";
    /**
     * The color of the notification.
     */
    color: ButtonProps["color"];
    /**
     * Optional icon to show at the leading edge of the notification.
     */
    startIcon?: React.ReactNode;
    /**
     * The primary textual content of the notification.
     */
    title: React.ReactNode;
    /**
     * The secondary textual content of the notification.
     */
    caption?: React.ReactNode;
    /**
     * Callback invoked when the user clicks on the notification (anywhere
     * except the close button).
     */
    onClick: () => void;
    /**
     * Optional icon to show at the trailing edge of the notification.
     */
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
            <RippleDisabledButton
                color={attributes.color}
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
                        {attributes.type == "messageSubText" ? (
                            <>
                                {attributes.caption && (
                                    <EllipsizedTypography variant="small">
                                        {attributes.caption}
                                    </EllipsizedTypography>
                                )}
                                <EllipsizedTypography
                                    sx={{ fontWeight: "medium" }}
                                >
                                    {attributes.title}
                                </EllipsizedTypography>
                            </>
                        ) : (
                            <>
                                <EllipsizedTypography
                                    sx={{ fontWeight: "medium" }}
                                >
                                    {attributes.title}
                                </EllipsizedTypography>
                                {attributes.caption && (
                                    <EllipsizedTypography variant="small">
                                        {attributes.caption}
                                    </EllipsizedTypography>
                                )}
                            </>
                        )}
                    </Stack>

                    {attributes.endIcon ? (
                        <IconButton
                            component="div"
                            onClick={attributes.onClick}
                            sx={{ fontSize: "36px", bgcolor: "fill.faint" }}
                        >
                            {attributes?.endIcon}
                        </IconButton>
                    ) : (
                        <IconButton
                            component="div"
                            onClick={handleClose}
                            sx={{ bgcolor: "fill.faint" }}
                        >
                            <CloseIcon />
                        </IconButton>
                    )}
                </Stack>
            </RippleDisabledButton>
        </Snackbar>
    );
};
