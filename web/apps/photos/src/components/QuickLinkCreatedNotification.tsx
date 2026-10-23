import { Copy01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import { Box } from "@mui/material";
import { Notification } from "ente-base/components/Notification";
import { t } from "i18next";
import React, { useEffect, useRef, useState } from "react";

interface QuickLinkCreatedNotificationProps {
    open: boolean;
    onClose: () => void;
    onCopy: () => void;
}

export const QuickLinkCreatedNotification: React.FC<
    QuickLinkCreatedNotificationProps
> = ({ open, onClose, onCopy }) => {
    const [copied, setCopied] = useState(false);
    const closeTimerRef = useRef<number | undefined>(undefined);

    useEffect(() => {
        if (open) {
            // Reset on open, not during the close animation.
            setCopied(false);
            return;
        }
        if (closeTimerRef.current) {
            window.clearTimeout(closeTimerRef.current);
            closeTimerRef.current = undefined;
        }
    }, [open]);

    useEffect(
        () => () => {
            if (closeTimerRef.current) {
                window.clearTimeout(closeTimerRef.current);
            }
        },
        [],
    );

    const handleCopy = () => {
        onCopy();
        setCopied(true);
        if (closeTimerRef.current) {
            window.clearTimeout(closeTimerRef.current);
        }
        closeTimerRef.current = window.setTimeout(() => {
            onClose();
            closeTimerRef.current = undefined;
        }, 2500);
    };

    return (
        <Notification
            open={open}
            onClose={onClose}
            keepOpenOnClick
            attributes={{
                color: "inherit",
                startIcon: null,
                title: t("link_created"),
                endIcon: copied ? (
                    <Box sx={{ color: "success.main", display: "flex" }}>
                        <HugeiconsIcon
                            icon={Tick02Icon}
                            size={22}
                            strokeWidth={1.8}
                        />
                    </Box>
                ) : (
                    <HugeiconsIcon
                        icon={Copy01Icon}
                        size={18}
                        strokeWidth={1.8}
                    />
                ),
                endIconLabel: t("copy_link"),
                onEndIconClick: handleCopy,
                showCloseButtonWithEndIcon: true,
            }}
        />
    );
};
