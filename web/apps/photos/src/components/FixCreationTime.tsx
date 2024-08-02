import log from "@/base/log";
import type { ParsedMetadataDate } from "@/media/file-metadata";
import { PhotoDateTimePicker } from "@/new/photos/components/PhotoDateTimePicker";
import {
    updateDateTimeOfEnteFiles,
    type FixOption,
} from "@/new/photos/services/fix-exif";
import { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";
import DialogBox from "@ente/shared/components/DialogBox/";
import {
    Button,
    FormControl,
    FormControlLabel,
    FormLabel,
    LinearProgress,
    Radio,
    RadioGroup,
} from "@mui/material";
import { ComfySpan } from "components/ExportInProgress";
import { useFormik } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useState } from "react";

export interface FixCreationTimeAttributes {
    files: EnteFile[];
}

/** The current state of the fixing process. */
type Status = "running" | "completed" | "completed-with-errors";

interface FormValues {
    option: FixOption;
    /* Only valid when {@link option} is "custom-time". */
    customDate: ParsedMetadataDate | undefined;
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
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });

    const galleryContext = useContext(GalleryContext);

    useEffect(() => {
        // TODO (MR): Not sure why this is needed
        if (attributes && isOpen && status !== "running") setStatus(undefined);
    }, [isOpen]);

    const onSubmit = async (values: FormValues) => {
        console.log({ values });
        setStatus("running");
        const completedWithErrors = await updateDateTimeOfEnteFiles(
            attributes.files,
            values.option,
            values.customDate,
            setProgressTracker,
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
        <DialogBox
            open={isOpen}
            onClose={hide}
            attributes={{ title, nonClosable: true }}
        >
            <div
                style={{
                    marginBottom: "10px",
                    display: "flex",
                    flexDirection: "column",
                    ...(status == "running" ? { alignItems: "center" } : {}),
                }}
            >
                {message && <div>{message}</div>}
                {status === "running" && <Progress {...{ progressTracker }} />}
                <OptionsForm {...{ step: status, onSubmit }} hide={hide} />
            </div>
        </DialogBox>
    );
};

export default FixCreationTime;

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

const Progress = ({ progressTracker }) => {
    const progress = Math.round(
        (progressTracker.current * 100) / progressTracker.total,
    );
    return (
        <>
            <div style={{ marginBottom: "10px" }}>
                <ComfySpan>
                    {" "}
                    {progressTracker.current} / {progressTracker.total}{" "}
                </ComfySpan>{" "}
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
                <LinearProgress variant="determinate" value={progress} />
            </div>
        </>
    );
};

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
                <div style={{ marginTop: "10px" }}>
                    <form onSubmit={handleSubmit}>
                        <FormControl>
                            <FormLabel>
                                {t("UPDATE_CREATION_TIME_NOT_STARTED")}
                            </FormLabel>
                        </FormControl>
                        <RadioGroup name={"option"} onChange={handleChange}>
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
                </div>
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
                        {t("CLOSE")}
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

type SetProgressTracker = React.Dispatch<
    React.SetStateAction<{
        current: number;
        total: number;
    }>
>;

const updateFiles = async (
    enteFiles: EnteFile[],
    fixOption: FixOption,
    customDate: ParsedMetadataDate,
    setProgressTracker: SetProgressTracker,
) => {
    setProgressTracker({ current: 0, total: enteFiles.length });
    let hadErrors = false;
    for (const [i, enteFile] of enteFiles.entries()) {
        try {
            await updateEnteFileDate(enteFile, fixOption, customDate);
        } catch (e) {
            log.error(`Failed to update date of ${fileLogID(enteFile)}`, e);
            hadErrors = true;
        } finally {
            setProgressTracker({ current: i + 1, total: enteFiles.length });
        }
    }
    return hadErrors;
};
