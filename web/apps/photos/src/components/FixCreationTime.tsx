import log from "@/base/log";
import { fileLogID, type EnteFile } from "@/media/file";
import {
    decryptPublicMagicMetadata,
    fileCreationPhotoDate,
    updateRemotePublicMagicMetadata,
    type ParsedMetadataDate,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import { PhotoDateTimePicker } from "@/new/photos/components/PhotoDateTimePicker";
import downloadManager from "@/new/photos/services/download";
import { extractExifDates } from "@/new/photos/services/exif";
import { ensure } from "@/utils/ensure";
import {
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    FormControl,
    FormControlLabel,
    FormLabel,
    LinearProgress,
    Radio,
    RadioGroup,
    Typography,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useState } from "react";

/** The current state of the fixing process. */
type Status = "running" | "completed" | "completed-with-errors";

export type FixOption =
    | "date-time-original"
    | "date-time-digitized"
    | "metadata-date"
    | "custom";

export interface FixCreationTimeAttributes {
    files: EnteFile[];
}

interface FixCreationTimeProps {
    isOpen: boolean;
    hide: () => void;
    attributes: FixCreationTimeAttributes;
}

const FixCreationTime: React.FC<FixCreationTimeProps> = ({
    isOpen,
    hide,
    attributes,
}) => {
    const [status, setStatus] = useState<Status | undefined>();
    const [progress, setProgress] = useState({ completed: 0, total: 0 });

    const galleryContext = useContext(GalleryContext);

    useEffect(() => {
        // TODO (MR): Not sure why this is needed
        if (attributes && isOpen && status !== "running") setStatus(undefined);
    }, [isOpen]);

    const onSubmit = async (values: FormValues) => {
        setStatus("running");
        const completedWithErrors = await updateFiles(
            attributes.files,
            values.option,
            values.customDate,
            setProgress,
        );
        setStatus(completedWithErrors ? "completed-with-errors" : "completed");
        await galleryContext.syncWithRemote();
    };

    const title =
        status == "running"
            ? t("FIX_CREATION_TIME_IN_PROGRESS")
            : t("FIX_CREATION_TIME");

    const message = messageForStatus(status);

    if (!attributes) {
        return <></>;
    }

    return (
        <Dialog
            open={isOpen}
            onClose={(_, reason) => {
                if (reason == "backdropClick") return;
                hide();
            }}
        >
            <DialogTitle>{title}</DialogTitle>
            <DialogContent
                style={{
                    minWidth: "310px",
                    display: "flex",
                    flexDirection: "column",
                    ...(status == "running" ? { alignItems: "center" } : {}),
                }}
            >
                {message && <Typography>{message}</Typography>}
                {status === "running" && <Progress {...progress} />}
                <OptionsForm {...{ step: status, onSubmit }} hide={hide} />
            </DialogContent>
        </Dialog>
    );
};

export default FixCreationTime;

interface FormValues {
    option: FixOption;
    /* Only valid when {@link option} is "custom-time". */
    customDate: ParsedMetadataDate | undefined;
}

interface FixProgress {
    completed: number;
    total: number;
}

const messageForStatus = (step?: Status) => {
    switch (step) {
        case undefined:
            return undefined;
        case "running":
            return undefined;
        case "completed":
            return t("UPDATE_CREATION_TIME_COMPLETED");
        case "completed-with-errors":
            return t("UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR");
    }
};

const Progress: React.FC<FixProgress> = ({ completed, total }) => {
    const percent = Math.round((completed * 100) / total);
    return (
        <>
            <div style={{ marginBottom: "10px" }}>
                <span>
                    {completed} / {total}
                </span>
                <span style={{ marginLeft: "10px" }}>
                    {" "}
                    {t("CREATION_TIME_UPDATED")}
                </span>
            </div>
            <div
                style={{
                    width: "100%",
                    marginTop: "10px",
                    marginBottom: "20px",
                }}
            >
                <LinearProgress variant="determinate" value={percent} />
            </div>
        </>
    );
};

// export const ComfySpan = styled("span")`
//     padding: 0 0.5rem;
//     word-spacing: 1rem;
//     color: #ddd;
// `;

interface OptionsFormProps {
    step?: Status;
    onSubmit: (values: FormValues) => Promise<void>;
    hide: () => void;
}

const OptionsForm: React.FC<OptionsFormProps> = ({ step, onSubmit, hide }) => {
    const { values, handleChange, setValues, handleSubmit } =
        useFormik<FormValues>({
            initialValues: {
                option: "date-time-original",
                customDate: undefined,
            },
            validateOnBlur: false,
            onSubmit,
        });

    return (
        <>
            {(step === undefined || step === "completed-with-errors") && (
                <form onSubmit={handleSubmit}>
                    <FormControl>
                        <FormLabel>
                            {t("UPDATE_CREATION_TIME_NOT_STARTED")}
                        </FormLabel>
                    </FormControl>
                    <RadioGroup
                        name={"option"}
                        value={values.option}
                        onChange={handleChange}
                        sx={{ paddingBlockStart: 1 }}
                    >
                        <FormControlLabel
                            value={"date-time-original"}
                            control={<Radio size="small" />}
                            label={t("DATE_TIME_ORIGINAL")}
                        />
                        <FormControlLabel
                            value={"date-time-digitized"}
                            control={<Radio size="small" />}
                            label={t("DATE_TIME_DIGITIZED")}
                        />
                        <FormControlLabel
                            value={"metadata-date"}
                            control={<Radio size="small" />}
                            label={t("METADATA_DATE")}
                        />
                        <FormControlLabel
                            value={"custom"}
                            control={<Radio size="small" />}
                            label={t("CUSTOM_TIME")}
                        />
                    </RadioGroup>
                    {values.option == "custom" && (
                        <PhotoDateTimePicker
                            onAccept={(customDate) =>
                                setValues({ option: "custom", customDate })
                            }
                        />
                    )}
                </form>
            )}
            <Footer step={step} startFix={handleSubmit} hide={hide} />
        </>
    );
};

const Footer = ({ step, startFix, ...props }) => {
    return (
        step != "running" && (
            <div
                style={{
                    width: "100%",
                    display: "flex",
                    marginTop: "30px",
                    justifyContent: "space-around",
                }}
            >
                {(!step || step == "completed-with-errors") && (
                    <Button
                        color="secondary"
                        size="large"
                        onClick={() => {
                            props.hide();
                        }}
                    >
                        {t("cancel")}
                    </Button>
                )}
                {step == "completed" && (
                    <Button color="primary" size="large" onClick={props.hide}>
                        {t("close")}
                    </Button>
                )}
                {(!step || step == "completed-with-errors") && (
                    <>
                        <div style={{ width: "30px" }} />

                        <Button color="accent" size="large" onClick={startFix}>
                            {t("FIX_CREATION_TIME")}
                        </Button>
                    </>
                )}
            </div>
        )
    );
};

const updateFiles = async (
    files: EnteFile[],
    fixOption: FixOption,
    customDate: ParsedMetadataDate | undefined,
    setProgress: (progress: FixProgress) => void,
) => {
    setProgress({ completed: 0, total: files.length });
    let hadErrors = false;
    for (const [i, file] of files.entries()) {
        try {
            await updateEnteFileDate(file, fixOption, customDate);
        } catch (e) {
            log.error(`Failed to update date of ${fileLogID(file)}`, e);
            hadErrors = true;
        } finally {
            setProgress({ completed: i + 1, total: files.length });
        }
    }
    return hadErrors;
};

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
 */
const updateEnteFileDate = async (
    enteFile: EnteFile,
    fixOption: FixOption,
    customDate: ParsedMetadataDate | undefined,
) => {
    let newDate: ParsedMetadataDate | undefined;

    if (fixOption == "custom") {
        newDate = {
            dateTime: ensure(customDate).dateTime,
            // See [Note: Don't modify offsetTime when editing date via picker]
            // for why we don't also set the offset here.
            offset: undefined,
            timestamp: ensure(customDate).timestamp,
        };
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

    if (!newDate) return;

    const existingDate = fileCreationPhotoDate(
        enteFile,
        await decryptPublicMagicMetadata(enteFile),
    );
    if (newDate.timestamp == existingDate.getTime()) return;

    await updateRemotePublicMagicMetadata(enteFile, {
        dateTime: newDate.dateTime,
        offsetTime: newDate.offset,
        editedTime: newDate.timestamp,
    });
};
