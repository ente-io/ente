import DialogBox from "@ente/shared/components/DialogBox/";
import { Button, LinearProgress, styled } from "@mui/material";
import { ComfySpan } from "components/ExportInProgress";
import { Field, Form, Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useState } from "react";
import { updateCreationTimeWithExif } from "services/updateCreationTimeWithExif";
import { EnteFile } from "types/file";
import EnteDateTimePicker from "./EnteDateTimePicker";

export interface FixCreationTimeAttributes {
    files: EnteFile[];
}

type Step = "running" | "completed" | "completed-with-errors";

export type FixOption =
    | "date-time-original"
    | "date-time-digitized"
    | "metadata-date"
    | "custom-time";

interface FormValues {
    option: FixOption;
    customTime: Date;
}

interface FixCreationTimeProps {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
    attributes: FixCreationTimeAttributes;
}

const FixCreationTime: React.FC<FixCreationTimeProps> = (props) => {
    const [step, setStep] = useState<Step | undefined>();
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });

    const galleryContext = useContext(GalleryContext);

    useEffect(() => {
        // TODO (MR): Not sure why this is needed
        if (props.attributes && props.isOpen && step !== "running") {
            setStep(undefined);
        }
    }, [props.isOpen]);

    const onSubmit = async (values: FormValues) => {
        setStep("running");
        const completedWithErrors = await updateCreationTimeWithExif(
            props.attributes.files,
            values.option,
            values.customTime,
            setProgressTracker,
        );
        setStep(completedWithErrors ? "completed-with-errors" : "completed");
        await galleryContext.syncWithRemote();
    };

    const title =
        step === "running"
            ? t("FIX_CREATION_TIME_IN_PROGRESS")
            : t("FIX_CREATION_TIME");

    const message = messageForStep(step);

    if (!props.attributes) {
        return <></>;
    }

    return (
        <DialogBox
            open={props.isOpen}
            onClose={props.hide}
            attributes={{ title, nonClosable: true }}
        >
            <div
                style={{
                    marginBottom: "10px",
                    display: "flex",
                    flexDirection: "column",
                    ...(step === "running" ? { alignItems: "center" } : {}),
                }}
            >
                {message && <div>{message}</div>}

                {step === "running" && (
                    <FixCreationTimeRunning {...{ progressTracker }} />
                )}

                <OptionsForm {...{ step, onSubmit }} hide={props.hide} />
            </div>
        </DialogBox>
    );
};

export default FixCreationTime;

const messageForStep = (step?: Step) => {
    switch (step) {
        case undefined:
            return t("UPDATE_CREATION_TIME_NOT_STARTED");
        case "running":
            return undefined;
        case "completed":
            return t("UPDATE_CREATION_TIME_COMPLETED");
        case "completed-with-errors":
            return t("UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR");
    }
};

interface OptionsFormProps {
    step?: Step;
    onSubmit: (
        values: FormValues,
        formikHelpers: FormikHelpers<FormValues>,
    ) => void | Promise<any>;
    hide: () => void;
}

const OptionsForm: React.FC<OptionsFormProps> = ({ step, onSubmit, hide }) => {
    return (
        <Formik<FormValues>
            initialValues={{
                option: "date-time-original",
                customTime: new Date(),
            }}
            validateOnBlur={false}
            onSubmit={onSubmit}
        >
            {({ values, handleChange, handleSubmit }) => (
                <>
                    {(step === undefined ||
                        step === "completed-with-errors") && (
                        <div style={{ marginTop: "10px" }}>
                            <Form>
                                <Option
                                    option={"date-time-original"}
                                    selectedOption={values.option}
                                    label={t("DATE_TIME_ORIGINAL")}
                                />

                                <Option
                                    option={"date-time-digitized"}
                                    selectedOption={values.option}
                                    label={t("DATE_TIME_DIGITIZED")}
                                />

                                <Option
                                    option={"metadata-date"}
                                    selectedOption={values.option}
                                    label={t("METADATA_DATE")}
                                />

                                <Option
                                    option={"custom-time"}
                                    selectedOption={values.option}
                                    label={t("CUSTOM_TIME")}
                                />
                                {values.option === "custom-time" && (
                                    <EnteDateTimePicker
                                        onSubmit={(x: Date) =>
                                            handleChange("customTime")(
                                                x.toUTCString(),
                                            )
                                        }
                                    />
                                )}
                            </Form>
                        </div>
                    )}
                    <Footer step={step} startFix={handleSubmit} hide={hide} />
                </>
            )}
        </Formik>
    );
};

interface OptionProps {
    option: FixOption;
    selectedOption: FixOption;
    label: string;
}

const Option: React.FC<OptionProps> = ({ option, selectedOption, label }) => {
    const isSelected = option === selectedOption;
    return (
        <Option_
            style={{
                color: isSelected ? "#aaa" : "#fff",
            }}
        >
            <label>
                <Field type="radio" name="option" value={option} />
                {label}
            </label>
        </Option_>
    );
};

const Option_ = styled("div")`
    margin-block: 5px;
`;

const Footer = ({ step, startFix, ...props }) => {
    return (
        step !== "running" && (
            <div
                style={{
                    width: "100%",
                    display: "flex",
                    marginTop: "30px",
                    justifyContent: "space-around",
                }}
            >
                {(step === undefined || step === "completed-with-errors") && (
                    <Button
                        color="secondary"
                        size="large"
                        onClick={() => {
                            props.hide();
                        }}
                    >
                        {t("CANCEL")}
                    </Button>
                )}
                {step === "completed" && (
                    <Button color="primary" size="large" onClick={props.hide}>
                        {t("CLOSE")}
                    </Button>
                )}
                {(step === undefined || step === "completed-with-errors") && (
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

const FixCreationTimeRunning = ({ progressTracker }) => {
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
