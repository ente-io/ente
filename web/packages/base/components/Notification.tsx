import "@fontsource-variable/outfit";
import {
    Cancel01Icon,
    InformationCircleIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon, type IconSvgElement } from "@hugeicons/react";
import {
    Box,
    IconButton,
    Paper,
    Snackbar,
    Stack,
    Typography,
    type ButtonProps,
    type SxProps,
    type Theme,
} from "@mui/material";
import { EllipsizedTypography } from "ente-base/components/Typography";
import { RippleDisabledButton } from "ente-base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import type {} from "ente-base/components/utils/mui-theme";
import { useNotificationContainer } from "ente-base/components/utils/notification-container";
import { isSxArray } from "ente-base/components/utils/sx";
import { t } from "i18next";
import React from "react";
import { createPortal } from "react-dom";

export interface NotificationAttributes {
    color: ButtonProps["color"];
    startIcon?: IconSvgElement | null;
    title: React.ReactNode;
    caption?: React.ReactNode;
    onClick?: () => void;
    endIcon?: IconSvgElement;
    endIconLabel?: string;
    onEndIconClick?: () => void;
}

type NotificationProps = ModalVisibilityProps & {
    attributes: NotificationAttributes | undefined;
    // A new event restarts the timeout, even when its message is unchanged.
    notificationID?: number;
    keepOpenOnClick?: boolean;
    horizontal?: "left" | "right";
    autoHideDuration?: number | null;
    sx?: SxProps<Theme>;
    onExited?: () => void;
};

const actionButtonSx = {
    width: 38,
    height: 38,
    p: 0,
    flexShrink: 0,
    borderRadius: "50%",
    color: "inherit",
    bgcolor: "fill.faint",
    "&:hover": { bgcolor: "fill.faintHover" },
    "&.Mui-focusVisible": {
        outline: "2px solid currentColor",
        outlineOffset: 2,
    },
};

/** Render a single notification or the independent notifications from useNotification. */
export const Notification: React.FC<
    | NotificationProps
    | {
          open: boolean;
          notifications: (NotificationProps & { notificationID: number })[];
      }
> = (props) => {
    if ("notifications" in props) {
        return props.notifications.map((notification) => (
            <NotificationItem
                key={notification.notificationID}
                {...notification}
            />
        ));
    }
    return <NotificationItem {...props} />;
};

const NotificationItem: React.FC<NotificationProps> = ({
    open,
    notificationID,
    onClose,
    horizontal = "right",
    autoHideDuration,
    sx,
    attributes,
    keepOpenOnClick,
    onExited,
}) => {
    const contentID = React.useId();
    const container = useNotificationContainer(horizontal);
    if (!attributes) return <></>;

    const {
        color,
        startIcon,
        title,
        caption,
        endIcon,
        endIconLabel,
        onClick,
        onEndIconClick,
    } = attributes;
    const resolvedAutoHideDuration =
        autoHideDuration === undefined
            ? onClick
                ? null
                : 3000
            : autoHideDuration;
    const neutral = !color || color === "inherit";
    const isClickable = !!onClick || !keepOpenOnClick;
    const buttonSx = {
        ...actionButtonSx,
        ...(neutral && {
            color: "text.muted",
            bgcolor: "fill.fainter",
            "&:hover": { bgcolor: "fill.faintHover", color: "text.base" },
        }),
    };

    const handleClick = () => {
        onClick?.();
        if (!keepOpenOnClick) onClose();
    };

    const captionElement = caption && (
        <EllipsizedTypography
            variant="small"
            title={typeof caption === "string" ? caption : undefined}
            sx={{
                fontFamily: "inherit",
                fontSize: 14,
                lineHeight: "20px",
                color: neutral ? "text.muted" : "inherit",
            }}
        >
            {caption}
        </EllipsizedTypography>
    );

    const content = (
        <Stack
            direction="row"
            sx={{ gap: 2, alignItems: "center", width: "100%", minWidth: 0 }}
        >
            {startIcon !== null && (
                <Stack
                    sx={{
                        flexShrink: 0,
                        svg: { width: 24, height: 24, fontSize: 24 },
                    }}
                >
                    <HugeiconsIcon
                        icon={startIcon ?? InformationCircleIcon}
                        size={24}
                        strokeWidth={1.8}
                    />
                </Stack>
            )}
            <Stack
                id={contentID}
                role="status"
                sx={{
                    flex: 1,
                    gap: 0.5,
                    textAlign: "left",
                    overflow: "hidden",
                }}
            >
                <Typography
                    noWrap
                    sx={{
                        fontFamily: "inherit",
                        fontSize: 18,
                        lineHeight: "24px",
                        fontWeight: 600,
                    }}
                >
                    {title}
                </Typography>
                {captionElement}
            </Stack>
        </Stack>
    );

    const notification = (
        <Snackbar
            key={notificationID}
            open={open}
            slotProps={{ transition: { onExited } }}
            autoHideDuration={resolvedAutoHideDuration}
            onClose={(_, reason) => {
                if (reason === "timeout") onClose();
            }}
            anchorOrigin={{ horizontal, vertical: "bottom" }}
            sx={[
                (theme) => ({
                    width: "min(340px, calc(100vw - 32px))",
                    left: horizontal === "left" ? { xs: 16, sm: 24 } : "auto",
                    right: horizontal === "right" ? { xs: 16, sm: 24 } : "auto",
                    bottom: { xs: 16, sm: 24 },
                    ...(container && {
                        "&&": {
                            position: "relative",
                            left: "auto",
                            right: "auto",
                            bottom: "auto",
                            transform: "none",
                        },
                    }),
                    pointerEvents: "auto",
                    borderRadius: "24px",
                    border: "1px solid",
                    borderColor: "rgba(0, 0, 0, 0.06)",
                    ...theme.applyStyles("dark", {
                        borderColor: "rgba(255, 255, 255, 0.06)",
                    }),
                    backgroundColor: neutral
                        ? "background.paper"
                        : `${color}.main`,
                    color: neutral ? "text.base" : `${color}.contrastText`,
                    boxShadow: "0 8px 32px rgba(0, 0, 0, 0.24)",
                }),
                ...(sx ? (isSxArray(sx) ? sx : [sx]) : []),
            ]}
        >
            <Paper
                onClick={isClickable ? handleClick : undefined}
                sx={{
                    cursor: isClickable ? "pointer" : undefined,
                    "&:hover": {
                        bgcolor: isClickable ? "action.hover" : undefined,
                    },
                    width: "100%",
                    minWidth: 0,
                    display: "flex",
                    alignItems: "center",
                    gap: 2,
                    px: 2.5,
                    py: 2,
                    borderRadius: "inherit",
                    bgcolor: "transparent",
                    backgroundImage: "none",
                    color: "inherit",
                    boxShadow: "none",
                    fontFamily: '"Outfit Variable", sans-serif',
                }}
            >
                {isClickable ? (
                    <RippleDisabledButton
                        variant="text"
                        color="inherit"
                        aria-labelledby={contentID}
                        sx={{
                            flex: 1,
                            minWidth: 0,
                            p: 0,
                            fontFamily: "inherit",
                            textAlign: "left",
                            "&:hover": { bgcolor: "transparent" },
                            "&.Mui-focusVisible": {
                                outline: "2px solid currentColor",
                                outlineOffset: 2,
                            },
                        }}
                    >
                        {content}
                    </RippleDisabledButton>
                ) : (
                    <Box sx={{ flex: 1, minWidth: 0 }}>{content}</Box>
                )}
                <Stack direction="row" sx={{ gap: 1, flexShrink: 0 }}>
                    {endIcon && (
                        <IconButton
                            aria-label={
                                endIconLabel ??
                                (typeof title === "string"
                                    ? title
                                    : t("more_information"))
                            }
                            onClick={(event) => {
                                event.stopPropagation();
                                if (onEndIconClick) onEndIconClick();
                                else handleClick();
                            }}
                            sx={buttonSx}
                        >
                            <HugeiconsIcon
                                icon={endIcon}
                                size={22}
                                strokeWidth={1.8}
                            />
                        </IconButton>
                    )}
                    <IconButton
                        aria-label={t("close")}
                        onClick={(event) => {
                            event.stopPropagation();
                            onClose();
                        }}
                        sx={buttonSx}
                    >
                        <HugeiconsIcon
                            icon={Cancel01Icon}
                            size={22}
                            strokeWidth={1.8}
                        />
                    </IconButton>
                </Stack>
            </Paper>
        </Snackbar>
    );
    return container ? createPortal(notification, container) : notification;
};
