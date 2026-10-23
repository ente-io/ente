import { Notification } from "ente-base/components/Notification";
import { t } from "i18next";
import React from "react";

export type AddToAlbumPhase = "processing" | "done" | "failed";

interface AlbumAddedNotificationProps {
    open: boolean;
    onClose: () => void;
    phase: AddToAlbumPhase;
    albumName?: string;
}

export const AlbumAddedNotification: React.FC<AlbumAddedNotificationProps> = ({
    open,
    onClose,
    phase,
    albumName,
}) => {
    const shouldShow = open && phase === "done";

    return (
        <Notification
            open={shouldShow}
            onClose={onClose}
            keepOpenOnClick
            attributes={{
                color: "inherit",
                startIcon: null,
                title: t("added_to_album"),
                caption: albumName,
            }}
        />
    );
};
