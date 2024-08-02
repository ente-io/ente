import log from "@/base/log";
import type { ParsedMetadataDate } from "@/media/file-metadata";
import { PhotoDateTimePicker } from "@/new/photos/components/PhotoDateTimePicker";
import { EnteFile } from "@/new/photos/types/file";
import { FlexWrapper } from "@ente/shared/components/Container";
import { formatDate, formatTime } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import { useState } from "react";
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from "utils/file";
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
                const unixTimeInMicroSec = pickedTime.timestamp;
                if (unixTimeInMicroSec === file?.metadata.creationTime) {
                    closeEditMode();
                    return;
                }
                const updatedFile = await changeFileCreationTime(
                    file,
                    unixTimeInMicroSec,
                );
                updateExistingFilePubMetadata(file, updatedFile);
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
