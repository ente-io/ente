import DialogBox from "@ente/shared/components/DialogBox/";
import { logError } from "@ente/shared/sentry";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { Button, ProgressBar } from "react-bootstrap";
import {
    getLargeThumbnailFiles,
    replaceThumbnail,
} from "services/migrateThumbnailService";
import { ComfySpan } from "./ExportInProgress";

export type SetProgressTracker = React.Dispatch<
    React.SetStateAction<{
        current: number;
        total: number;
    }>
>;
interface Props {
    isOpen: boolean;
    show: () => void;
    hide: () => void;
}
export enum FIX_STATE {
    NOT_STARTED,
    FIX_LATER,
    NOOP,
    RUNNING,
    COMPLETED,
    COMPLETED_WITH_ERRORS,
}
function Message({ fixState }: { fixState: FIX_STATE }) {
    let message = null;
    switch (fixState) {
        case FIX_STATE.NOT_STARTED:
        case FIX_STATE.FIX_LATER:
            message = t("REPLACE_THUMBNAIL_NOT_STARTED");
            break;
        case FIX_STATE.COMPLETED:
            message = t("REPLACE_THUMBNAIL_COMPLETED");
            break;
        case FIX_STATE.NOOP:
            message = t("REPLACE_THUMBNAIL_NOOP");
            break;
        case FIX_STATE.COMPLETED_WITH_ERRORS:
            message = t("REPLACE_THUMBNAIL_COMPLETED_WITH_ERROR");
            break;
    }
    return message ? (
        <div style={{ marginBottom: "30px" }}>{message}</div>
    ) : (
        <></>
    );
}
export default function FixLargeThumbnails(props: Props) {
    const [fixState, setFixState] = useState(FIX_STATE.NOT_STARTED);
    const [progressTracker, setProgressTracker] = useState({
        current: 0,
        total: 0,
    });
    const [largeThumbnailFiles, setLargeThumbnailFiles] = useState<number[]>(
        [],
    );

    const init = (): FIX_STATE => {
        let fixState = getData(LS_KEYS.THUMBNAIL_FIX_STATE)?.state;
        if (!fixState || fixState === FIX_STATE.RUNNING) {
            fixState = FIX_STATE.NOT_STARTED;
            updateFixState(fixState);
        }
        if (fixState === FIX_STATE.COMPLETED) {
            fixState = FIX_STATE.NOOP;
            updateFixState(fixState);
        }
        setFixState(fixState);
        return fixState;
    };

    const fetchLargeThumbnail = async () => {
        const largeThumbnailFiles = (await getLargeThumbnailFiles()) ?? [];
        setLargeThumbnailFiles(largeThumbnailFiles);
        return largeThumbnailFiles;
    };

    const main = async () => {
        const largeThumbnailFiles = await fetchLargeThumbnail();
        if (
            fixState === FIX_STATE.NOT_STARTED &&
            largeThumbnailFiles.length > 0
        ) {
            props.show();
        }
        if (
            (fixState === FIX_STATE.COMPLETED || fixState === FIX_STATE.NOOP) &&
            largeThumbnailFiles.length > 0
        ) {
            updateFixState(FIX_STATE.NOT_STARTED);
            logError(Error(), "large thumbnail files left after migration");
        }
        if (largeThumbnailFiles.length === 0 && fixState !== FIX_STATE.NOOP) {
            updateFixState(FIX_STATE.NOOP);
        }
    };
    useEffect(() => {
        if (props.isOpen && fixState !== FIX_STATE.RUNNING) {
            main();
        }
    }, [props.isOpen]);

    useEffect(() => {
        const fixState = init();
        if (fixState === FIX_STATE.NOT_STARTED) {
            main();
        }
    }, []);
    const startFix = async (newlyFetchedLargeThumbnailFiles?: number[]) => {
        updateFixState(FIX_STATE.RUNNING);
        const completedWithError = await replaceThumbnail(
            setProgressTracker,
            new Set(
                newlyFetchedLargeThumbnailFiles ?? largeThumbnailFiles ?? [],
            ),
        );
        if (typeof completedWithError !== "undefined") {
            updateFixState(
                completedWithError
                    ? FIX_STATE.COMPLETED_WITH_ERRORS
                    : FIX_STATE.COMPLETED,
            );
        }
        await fetchLargeThumbnail();
    };

    const updateFixState = (fixState: FIX_STATE) => {
        setFixState(fixState);
        setData(LS_KEYS.THUMBNAIL_FIX_STATE, { state: fixState });
    };
    return (
        <DialogBox
            open={props.isOpen}
            onClose={props.hide}
            attributes={{
                title: t("COMPRESS_THUMBNAILS"),
            }}
        >
            <div
                style={{
                    marginBottom: "20px",
                    padding: "0 5%",
                    display: "flex",
                    alignItems: "center",
                    flexDirection: "column",
                }}
            >
                <Message fixState={fixState} />

                {fixState === FIX_STATE.RUNNING && (
                    <>
                        <div style={{ marginBottom: "10px" }}>
                            <ComfySpan>
                                {" "}
                                {progressTracker.current} /{" "}
                                {progressTracker.total}{" "}
                            </ComfySpan>{" "}
                            <span style={{ marginLeft: "10px" }}>
                                {" "}
                                {t("THUMBNAIL_REPLACED")}
                            </span>
                        </div>
                        <div
                            style={{
                                width: "100%",
                                marginTop: "10px",
                                marginBottom: "20px",
                            }}
                        >
                            <ProgressBar
                                now={Math.round(
                                    (progressTracker.current * 100) /
                                        progressTracker.total,
                                )}
                                animated={true}
                                variant="upload-progress-bar"
                            />
                        </div>
                    </>
                )}
                <div
                    style={{
                        width: "100%",
                        display: "flex",
                        justifyContent: "space-around",
                    }}
                >
                    {fixState === FIX_STATE.NOT_STARTED ||
                    fixState === FIX_STATE.FIX_LATER ? (
                        <Button
                            block
                            variant={"outline-secondary"}
                            onClick={() => {
                                updateFixState(FIX_STATE.FIX_LATER);
                                props.hide();
                            }}
                        >
                            {t("FIX_THUMBNAIL_LATER")}
                        </Button>
                    ) : (
                        <Button
                            block
                            variant={"outline-secondary"}
                            onClick={props.hide}
                        >
                            {t("CLOSE")}
                        </Button>
                    )}
                    {(fixState === FIX_STATE.NOT_STARTED ||
                        fixState === FIX_STATE.FIX_LATER ||
                        fixState === FIX_STATE.COMPLETED_WITH_ERRORS) && (
                        <>
                            <div style={{ width: "30px" }} />

                            <Button
                                block
                                variant={"outline-success"}
                                onClick={() => startFix()}
                            >
                                {t("FIX_THUMBNAIL")}
                            </Button>
                        </>
                    )}
                </div>
            </div>
        </DialogBox>
    );
}
