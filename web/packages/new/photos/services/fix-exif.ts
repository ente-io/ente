import type { ParsedMetadataDate } from "@/media/file-metadata";
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import downloadManager from "@/new/photos/services/download";
import type { EnteFile } from "@/new/photos/types/file";
import { extractExifDates } from "./exif";

export type FixOption =
    | "date-time-original"
    | "date-time-digitized"
    | "metadata-date"
    | "custom";

/**
 * Update the date associated with a given {@link enteFile}.
 *
 * This is generally treated as the creation date of the underlying asset
 * (photo, video, live photo) that this file stores.
 *
 * -   For images, this function allows us to update this date from the Exif and
 *     other metadata embedded in the file.
 *
 * -   For all types of files (including images), this function allows us to
 *     update this date to an explicitly provided value.
 *
 * If an Exif-involving {@link fixOption} is passed for an non-image file, then
 * that file is just skipped over. Similarly, if an Exif-involving
 * {@link fixOption} is provided, but the given underlying image for the given
 * {@link enteFile} does not have a corresponding Exif (or related) value, then
 * that file is skipped.
 *
 * Note that metadata associated with an {@link EnteFile} is immutable, and we
 * instead modify the mutable metadata section associated with the file. See
 * [Note: Metadatum] for more details.
 */
export const updateEnteFileDate = async (
    enteFile: EnteFile,
    fixOption: FixOption,
    customDate: ParsedMetadataDate,
) => {
    let newDate: ParsedMetadataDate | undefined;
    if (fixOption === "custom") {
        newDate = customDate;
    } else if (enteFile.metadata.fileType == FileType.image) {
        const stream = await downloadManager.getFile(enteFile);
        const blob = await new Response(stream).blob();
        const file = new File([blob], enteFile.metadata.title);
        const { DateTimeOriginal, DateTimeDigitized, MetadataDate, DateTime } =
            await extractExifDates(file);
        switch (fixOption) {
            case "date-time-original":
                newDate = DateTimeOriginal ?? DateTime;
                break;
            case "date-time-digitized":
                newDate = DateTimeDigitized;
                break;
            case "metadata-date":
                newDate = MetadataDate;
                break;
        }
    }

    if (newDate && newDate.timestamp !== enteFile.metadata.creationTime) {
        const updatedFile = await changeFileCreationTime(
            enteFile,
            newDate.timestamp,
        );
        updateExistingFilePubMetadata(enteFile, updatedFile);
    }
};
