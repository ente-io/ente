import { Button } from "@mui/material";
import { t } from "i18next";
import { FIX_STATE } from ".";

export default function FixCreationTimeFooter({
    fixState,
    startFix,
    ...props
}) {
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
}
