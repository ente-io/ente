import { Row, Value } from "@ente/shared/components/Container";
import DialogBox from "@ente/shared/components/DialogBox/";
import { Button, LinearProgress } from "@mui/material";
import EnteDateTimePicker from "components/EnteDateTimePicker";
import { ComfySpan } from "components/ExportInProgress";
import { Formik } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { ChangeEvent, useContext, useEffect, useState } from "react";
import { Form } from "react-bootstrap";
import { updateCreationTimeWithExif } from "services/updateCreationTimeWithExif";
import { EnteFile } from "types/file";

export interface FixCreationTimeAttributes {
    files: EnteFile[];
}

interface Props {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
    attributes: FixCreationTimeAttributes;
}

enum FIX_STATE {
    NOT_STARTED,
    RUNNING,
    COMPLETED,
    COMPLETED_WITH_ERRORS,
}

enum FIX_OPTIONS {
    DATE_TIME_ORIGINAL,
    DATE_TIME_DIGITIZED,
    METADATA_DATE,
    CUSTOM_TIME,
}

interface formValues {
    option: FIX_OPTIONS;
    customTime: Date;
}

function Message({ fixState }: { fixState: FIX_STATE }) {
    let message = null;
    switch (fixState) {
        case FIX_STATE.NOT_STARTED:
            message = t("UPDATE_CREATION_TIME_NOT_STARTED");
            break;
        case FIX_STATE.COMPLETED:
            message = t("UPDATE_CREATION_TIME_COMPLETED");
            break;
        case FIX_STATE.COMPLETED_WITH_ERRORS:
            message = t("UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR");
            break;
    }
    return message ? <div>{message}</div> : <></>;
}

export default function FixCreationTime(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });
    const galleryContext = useContext(GalleryContext);
    useEffect(() => {
        if (
            props.attributes &&
            props.isOpen &&
            fixState !== FIX_STATE.RUNNING
        ) {
            setFixState(FIX_STATE.NOT_STARTED);
        }
    }, [props.isOpen]);

    const startFix = async (option: FIX_OPTIONS, customTime: Date) => {
        setFixState(FIX_STATE.RUNNING);
        const completedWithoutError = await updateCreationTimeWithExif(
            props.attributes.files,
            option,
            customTime,
            setProgressTracker,
        );
        if (!completedWithoutError) {
            setFixState(FIX_STATE.COMPLETED);
        } else {
            setFixState(FIX_STATE.COMPLETED_WITH_ERRORS);
        }
        await galleryContext.syncWithRemote();
    };
    if (!props.attributes) {
        return <></>;
    }

    const onSubmit = (values: formValues) => {
        startFix(Number(values.option), new Date(values.customTime));
    };

    return (
        <DialogBox
            open={props.isOpen}
            onClose={props.hide}
            attributes={{
                title:
                    fixState === FIX_STATE.RUNNING
                        ? t("FIX_CREATION_TIME_IN_PROGRESS")
                        : t("FIX_CREATION_TIME"),
                nonClosable: true,
            }}
        >
            <div
                style={{
                    marginBottom: "10px",
                    display: "flex",
                    flexDirection: "column",
                    ...(fixState === FIX_STATE.RUNNING
                        ? { alignItems: "center" }
                        : {}),
                }}
            >
                <Message fixState={fixState} />

                {fixState === FIX_STATE.RUNNING && (
                    <FixCreationTimeRunning progressTracker={progressTracker} />
                )}
                <Formik<formValues>
                    initialValues={{
                        option: FIX_OPTIONS.DATE_TIME_ORIGINAL,
                        customTime: new Date(),
                    }}
                    validateOnBlur={false}
                    onSubmit={onSubmit}
                >
                    {({ values, handleChange, handleSubmit }) => (
                        <>
                            {(fixState === FIX_STATE.NOT_STARTED ||
                                fixState ===
                                    FIX_STATE.COMPLETED_WITH_ERRORS) && (
                                <div style={{ marginTop: "10px" }}>
                                    <FixCreationTimeOptions
                                        handleChange={handleChange}
                                        values={values}
                                    />
                                </div>
                            )}
                            <FixCreationTimeFooter
                                fixState={fixState}
                                startFix={handleSubmit}
                                hide={props.hide}
                            />
                        </>
                    )}
                </Formik>
            </div>
        </DialogBox>
    );
}

const Option = ({
    value,
    selected,
    onChange,
    label,
}: {
    value: FIX_OPTIONS;
    selected: FIX_OPTIONS;
    onChange: (e: string | ChangeEvent<any>) => void;
    label: string;
}) => (
    <Form.Check
        name="group1"
        style={{
            margin: "5px 0",
            color: value !== Number(selected) ? "#aaa" : "#fff",
        }}
    >
        <Form.Check.Input
            id={value.toString()}
            type="radio"
            value={value}
            checked={value === Number(selected)}
            onChange={onChange}
        />
        <Form.Check.Label
            style={{ cursor: "pointer" }}
            htmlFor={value.toString()}
        >
            {label}
        </Form.Check.Label>
    </Form.Check>
);

function FixCreationTimeOptions({ handleChange, values }) {
    return (
        <Form noValidate>
            <Row style={{ margin: "0" }}>
                <Option
                    value={FIX_OPTIONS.DATE_TIME_ORIGINAL}
                    onChange={handleChange("option")}
                    label={t("DATE_TIME_ORIGINAL")}
                    selected={Number(values.option)}
                />
            </Row>
            <Row style={{ margin: "0" }}>
                <Option
                    value={FIX_OPTIONS.DATE_TIME_DIGITIZED}
                    onChange={handleChange("option")}
                    label={t("DATE_TIME_DIGITIZED")}
                    selected={Number(values.option)}
                />
            </Row>
            <Row style={{ margin: "0" }}>
                <Option
                    value={FIX_OPTIONS.METADATA_DATE}
                    onChange={handleChange("option")}
                    label={t("METADATA_DATE")}
                    selected={Number(values.option)}
                />
            </Row>
            <Row style={{ margin: "0" }}>
                <Value width="50%">
                    <Option
                        value={FIX_OPTIONS.CUSTOM_TIME}
                        onChange={handleChange("option")}
                        label={t("CUSTOM_TIME")}
                        selected={Number(values.option)}
                    />
                </Value>
                {Number(values.option) === FIX_OPTIONS.CUSTOM_TIME && (
                    <Value width="40%">
                        <EnteDateTimePicker
                            onSubmit={(x: Date) =>
                                handleChange("customTime")(x.toUTCString())
                            }
                        />
                    </Value>
                )}
            </Row>
        </Form>
    );
}

const FixCreationTimeFooter = ({ fixState, startFix, ...props }) => {
    return (
        fixState !== FIX_STATE.RUNNING && (
            <div
                style={{
                    width: "100%",
                    display: "flex",
                    marginTop: "30px",
                    justifyContent: "space-around",
                }}
            >
                {(fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
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
                {fixState === FIX_STATE.COMPLETED && (
                    <Button color="primary" size="large" onClick={props.hide}>
                        {t("CLOSE")}
                    </Button>
                )}
                {(fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
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
