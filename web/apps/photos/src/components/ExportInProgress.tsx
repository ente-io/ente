import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import {
    Box,
    Button,
    DialogActions,
    DialogContent,
    LinearProgress,
    styled,
} from "@mui/material";
import { ExportStage } from "constants/export";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { ExportProgress } from "types/export";

export const ComfySpan = styled("span")`
    padding: 0 0.5rem;
    word-spacing: 1rem;
    color: #ddd;
`;

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
                    <Box mb={1.5}>
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
                            <Trans
                                i18nKey={"EXPORT_PROGRESS"}
                                components={{
                                    a: <ComfySpan />,
                                }}
                                values={{
                                    progress: props.exportProgress,
                                }}
                            />
                        )}
                    </Box>
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
                <Button
                    color="secondary"
                    size="large"
                    onClick={props.closeExportDialog}
                >
                    {t("CLOSE")}
                </Button>
                <Button
                    size="large"
                    color="critical"
                    onClick={props.stopExport}
                >
                    {t("STOP_EXPORT")}
                </Button>
            </DialogActions>
        </>
    );
}
