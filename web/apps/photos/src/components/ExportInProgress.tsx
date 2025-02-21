import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import {
    DialogActions,
    DialogContent,
    LinearProgress,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { ExportStage, type ExportProgress } from "services/export";

interface Props {
    exportStage: ExportStage;
    exportProgress: ExportProgress;
    stopExport: () => void;
    closeExportDialog: () => void;
}

export default function ExportInProgress(props: Props) {
    const showIndeterminateProgress = () => {
        return (
            props.exportStage === ExportStage.STARTING ||
            props.exportStage === ExportStage.MIGRATION ||
            props.exportStage === ExportStage.RENAMING_COLLECTION_FOLDERS ||
            props.exportStage === ExportStage.TRASHING_DELETED_FILES ||
            props.exportStage === ExportStage.TRASHING_DELETED_COLLECTIONS
        );
    };
    return (
        <>
            <DialogContent>
                <VerticallyCentered>
                    <Typography sx={{ mb: 1.5 }}>
                        {props.exportStage === ExportStage.STARTING ? (
                            t("EXPORT_STARTING")
                        ) : props.exportStage === ExportStage.MIGRATION ? (
                            t("MIGRATING_EXPORT")
                        ) : props.exportStage ===
                          ExportStage.RENAMING_COLLECTION_FOLDERS ? (
                            t("RENAMING_COLLECTION_FOLDERS")
                        ) : props.exportStage ===
                          ExportStage.TRASHING_DELETED_FILES ? (
                            t("TRASHING_DELETED_FILES")
                        ) : props.exportStage ===
                          ExportStage.TRASHING_DELETED_COLLECTIONS ? (
                            t("TRASHING_DELETED_COLLECTIONS")
                        ) : (
                            <Typography
                                component="span"
                                sx={{ color: "text.muted" }}
                            >
                                <Trans
                                    i18nKey={"EXPORT_PROGRESS"}
                                    components={{
                                        a: (
                                            <Typography
                                                component="span"
                                                sx={{
                                                    color: "text.base",
                                                    pr: "1rem",
                                                    wordSpacing: "1rem",
                                                }}
                                            />
                                        ),
                                    }}
                                    values={{
                                        progress: props.exportProgress,
                                    }}
                                />
                            </Typography>
                        )}
                    </Typography>
                    <FlexWrapper px={1}>
                        {showIndeterminateProgress() ? (
                            <LinearProgress />
                        ) : (
                            <LinearProgress
                                variant="determinate"
                                value={Math.round(
                                    ((props.exportProgress.success +
                                        props.exportProgress.failed) *
                                        100) /
                                        props.exportProgress.total,
                                )}
                            />
                        )}
                    </FlexWrapper>
                </VerticallyCentered>
            </DialogContent>
            <DialogActions>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={props.closeExportDialog}
                >
                    {t("close")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    fullWidth
                    color="critical"
                    onClick={props.stopExport}
                >
                    {t("stop")}
                </FocusVisibleButton>
            </DialogActions>
        </>
    );
}
