import { EllipsizedTypography } from "@/base/components/Typography";
import { FilledIconButton } from "@/base/components/mui";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import CloseIcon from "@mui/icons-material/Close";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    Button,
    Snackbar,
    Stack,
    SxProps,
    Theme,
    type ButtonProps,
} from "@mui/material";
import React, { ReactNode } from "react";

/**
 * Customize the contents of an {@link Notification}.
 */
export type NotificationAttributes =
    | MessageSubTextNotificationAttributes
    | TitleCaptionNotificationAttributes;

interface MessageSubTextNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    message?: React.JSX.Element | string;
    subtext?: React.JSX.Element | string;
    title?: never;
    caption?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

interface TitleCaptionNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    title?: React.JSX.Element | string;
    caption?: React.JSX.Element | string;
    message?: never;
    subtext?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

type NotificationProps = ModalVisibilityProps & {
    keepOpenOnClick?: boolean;
    attributes: NotificationAttributes;
    horizontal?: "left" | "right";
    vertical?: "top" | "bottom";
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
    if (!attributes) {
        return <></>;
    }

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
            sx={{ width: "320px", backgroundColor: "#000", ...sx }}
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
