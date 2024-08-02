import type { ParsedMetadataDate } from "@/media/file-metadata";
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import downloadManager from "@/new/photos/services/download";
import type { EnteFile } from "@/new/photos/types/file";
import { detectFileTypeInfo } from "@/new/photos/utils/detect-type";
import { validateAndGetCreationUnixTimeInMicroSeconds } from "@ente/shared/time";
import { getParsedExifData } from "@ente/shared/utils/exif-old";

const EXIF_TIME_TAGS = [
    "DateTimeOriginal",
    "CreateDate",
    "ModifyDate",
    "DateCreated",
    "MetadataDate",
];

export type FixOption =
    | "date-time-original"
    | "date-time-digitized"
    | "metadata-date"
    | "custom";

/**
 * Update the date associated with a given {@link enteFile}.
 *
 * This is generally viewed as the creation date of the underlying asset
 * (photo, video, live photo) that this file stores.
 *
 * - For images, this function allows us to update this date from the
 *   Exif and other metadata embedded in the file.
 *
 * - For all types of files (including images), this function allows us to
 *   update this date to an explicitly provided value.
 *
 * If an Exif-involving {@link FixOption} is passed for an non-image file,
 * then that file is just skipped over.
 *
 * Note that the metadata associated with a file is immutable, and we
 * instead modify the mutable metadata section associated with the file. See
 * [Note: Metadatum] for more details.
 */
export const updateEnteFileDate = async (
    file: EnteFile,
    fixOption: FixOption,
    customDate: ParsedMetadataDate,
) => {
    let correctCreationTime: number | null;
    if (fixOption === "custom") {
        correctCreationTime = customDate.timestamp;
    } else {
        if (file.metadata.fileType !== FileType.image) {
            return;
        }
        const fileStream = await downloadManager.getFile(file);
        const fileBlob = await new Response(fileStream).blob();
        const fileObject = new File([fileBlob], file.metadata.title);
        const fileTypeInfo = await detectFileTypeInfo(fileObject);
        const exifData = await getParsedExifData(
            fileObject,
            fileTypeInfo,
            EXIF_TIME_TAGS,
        );
        if (fixOption === "date-time-original") {
            correctCreationTime = validateAndGetCreationUnixTimeInMicroSeconds(
                exifData?.DateTimeOriginal ?? exifData?.DateCreated,
            );
        } else if (fixOption === "date-time-digitized") {
            correctCreationTime = validateAndGetCreationUnixTimeInMicroSeconds(
                exifData?.CreateDate,
            );
        } else if (fixOption === "metadata-date") {
            correctCreationTime = validateAndGetCreationUnixTimeInMicroSeconds(
                exifData?.MetadataDate,
            );
        }
    }
    if (
        correctCreationTime &&
        correctCreationTime !== file.metadata.creationTime
    ) {
        const updatedFile = await changeFileCreationTime(
            file,
            correctCreationTime,
        );
        updateExistingFilePubMetadata(file, updatedFile);
    }
};
