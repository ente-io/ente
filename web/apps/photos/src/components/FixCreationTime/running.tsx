import { ComfySpan } from "components/ExportInProgress";
import { t } from "i18next";
import { ProgressBar } from "react-bootstrap";

export default function FixCreationTimeRunning({ progressTracker }) {
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
                <ProgressBar
                    now={Math.round(
                        (progressTracker.current * 100) / progressTracker.total,
                    )}
                    animated={true}
                    variant="upload-progress-bar"
                />
            </div>
        </>
    );
}
