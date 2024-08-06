import log from "@/base/log";
import {
    updateRemotePublicMagicMetadata,
    type ParsedMetadataDate,
} from "@/media/file-metadata";
import { PhotoDateTimePicker } from "@/new/photos/components/PhotoDateTimePicker";
import { EnteFile } from "@/new/photos/types/file";
import { FlexWrapper } from "@ente/shared/components/Container";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { formatDate, formatTime } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import { useState } from "react";
import InfoItem from "./InfoItem";

export function RenderCreationTime({
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}) {
    const [loading, setLoading] = useState(false);
    const originalCreationTime = new Date(file?.metadata.creationTime / 1000);
    const [isInEditMode, setIsInEditMode] = useState(false);

    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const saveEdits = async (pickedTime: ParsedMetadataDate) => {
        try {
            setLoading(true);
            if (isInEditMode && file) {
                // Use the updated date time (both in its canonical dateTime
                // form, and also as the legacy timestamp). But don't use the
                // offset. The offset here will be the offset of the computer
                // where this user is making this edit, not the offset of the
                // place where the photo was taken. In a future iteration of the
                // date time editor, we can provide functionality for the user
                // to edit the associated offset, but right now it is not even
                // surfaced, so don't also potentially overwrite it.
                const { dateTime, timestamp } = pickedTime;
                if (timestamp == file?.metadata.creationTime) {
                    // Same as before.
                    closeEditMode();
                    return;
                }

                log.debug(() => ["before", file.pubMagicMetadata]);

                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
                await updateRemotePublicMagicMetadata(
                    file,
                    { dateTime, editedTime: timestamp },
                    cryptoWorker.encryptMetadata,
                    cryptoWorker.decryptMetadata,
                );

                log.debug(() => ["after", file.pubMagicMetadata]);

                scheduleUpdate();
            }
        } catch (e) {
            log.error("failed to update creationTime", e);
        } finally {
            closeEditMode();
            setLoading(false);
        }
    };

    return (
        <>
            <FlexWrapper>
                <InfoItem
                    icon={<CalendarTodayIcon />}
                    title={formatDate(originalCreationTime)}
                    caption={formatTime(originalCreationTime)}
                    openEditor={openEditMode}
                    loading={loading}
                    hideEditOption={shouldDisableEdits || isInEditMode}
                />
                {isInEditMode && (
                    <PhotoDateTimePicker
                        initialValue={originalCreationTime}
                        disabled={loading}
                        onAccept={saveEdits}
                        onClose={closeEditMode}
                    />
                )}
            </FlexWrapper>
        </>
    );
}
