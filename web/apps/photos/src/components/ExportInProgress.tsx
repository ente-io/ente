import {
    DialogActions,
    DialogContent,
    LinearProgress,
    Typography,
} from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    FlexWrapper,
    VerticallyCentered,
} from "ente-shared/components/Container";
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
            props.exportStage === ExportStage.starting ||
            props.exportStage === ExportStage.migration ||
            props.exportStage === ExportStage.renamingCollectionFolders ||
            props.exportStage === ExportStage.trashingDeletedFiles ||
            props.exportStage === ExportStage.trashingDeletedCollections
        );
    };
    return (
        <>
            <DialogContent>
                <VerticallyCentered>
                    <Typography sx={{ mb: 1.5 }}>
                        {props.exportStage === ExportStage.starting ? (
                            t("export_starting")
                        ) : props.exportStage === ExportStage.migration ? (
                            t("preparing")
                        ) : props.exportStage ===
                          ExportStage.renamingCollectionFolders ? (
                            t("renaming_album_folders")
                        ) : props.exportStage ===
                          ExportStage.trashingDeletedFiles ? (
                            t("trashing_deleted_files")
                        ) : props.exportStage ===
                          ExportStage.trashingDeletedCollections ? (
                            t("trashing_deleted_albums")
                        ) : (
                            <Typography
                                component="span"
                                sx={{ color: "text.muted" }}
                            >
                                <Trans
                                    i18nKey={"export_progress"}
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
                                    values={{ progress: props.exportProgress }}
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
