import { UPLOAD_RESULT } from "@/new/photos/services/upload/types";
import { Dialog, DialogContent, type DialogProps } from "@mui/material";
import { t } from "i18next";
import { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import UploadProgressContext from "./context";
import { UploadProgressFooter } from "./footer";
import { UploadProgressHeader } from "./header";
import { InProgressSection } from "./inProgressSection";
import { ResultSection } from "./resultSection";
import { NotUploadSectionHeader } from "./styledComponents";

export function UploadProgressDialog() {
    const { open, onClose, uploadPhase, finishedUploads } = useContext(
        UploadProgressContext,
    );

    const [hasUnUploadedFiles, setHasUnUploadedFiles] = useState(false);

    useEffect(() => {
        if (
            finishedUploads.get(UPLOAD_RESULT.ALREADY_UPLOADED)?.length > 0 ||
            finishedUploads.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ||
            finishedUploads.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
            finishedUploads.get(UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE)
                ?.length > 0 ||
            finishedUploads.get(UPLOAD_RESULT.TOO_LARGE)?.length > 0 ||
            finishedUploads.get(UPLOAD_RESULT.UNSUPPORTED)?.length > 0
        ) {
            setHasUnUploadedFiles(true);
        } else {
            setHasUnUploadedFiles(false);
        }
    }, [finishedUploads]);

    const handleClose: DialogProps["onClose"] = (_, reason) => {
        if (reason != "backdropClick") onClose();
    };

    return (
        <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
            <UploadProgressHeader />
            {(uploadPhase == "extractingMetadata" ||
                uploadPhase == "uploading" ||
                uploadPhase == "done") && (
                <DialogContent sx={{ "&&&": { px: 0 } }}>
                    {(uploadPhase == "extractingMetadata" ||
                        uploadPhase === "uploading") && <InProgressSection />}
                    {(uploadPhase == "uploading" || uploadPhase == "done") && (
                        <>
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.UPLOADED}
                                sectionTitle={t("SUCCESSFUL_UPLOADS")}
                            />
                            <ResultSection
                                uploadResult={
                                    UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                                }
                                sectionTitle={t(
                                    "THUMBNAIL_GENERATION_FAILED_UPLOADS",
                                )}
                                sectionInfo={t(
                                    "THUMBNAIL_GENERATION_FAILED_INFO",
                                )}
                            />
                            {uploadPhase == "done" && hasUnUploadedFiles && (
                                <NotUploadSectionHeader>
                                    {t("FILE_NOT_UPLOADED_LIST")}
                                </NotUploadSectionHeader>
                            )}
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.BLOCKED}
                                sectionTitle={t("BLOCKED_UPLOADS")}
                                sectionInfo={
                                    <Trans i18nKey={"ETAGS_BLOCKED"} />
                                }
                            />
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.FAILED}
                                sectionTitle={t("FAILED_UPLOADS")}
                                sectionInfo={
                                    uploadPhase == "done"
                                        ? undefined
                                        : t("failed_uploads_hint")
                                }
                            />
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.ALREADY_UPLOADED}
                                sectionTitle={t("SKIPPED_FILES")}
                                sectionInfo={t("SKIPPED_INFO")}
                            />
                            <ResultSection
                                uploadResult={
                                    UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE
                                }
                                sectionTitle={t(
                                    "LARGER_THAN_AVAILABLE_STORAGE_UPLOADS",
                                )}
                                sectionInfo={t(
                                    "LARGER_THAN_AVAILABLE_STORAGE_INFO",
                                )}
                            />
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.UNSUPPORTED}
                                sectionTitle={t("UNSUPPORTED_FILES")}
                                sectionInfo={t("UNSUPPORTED_INFO")}
                            />
                            <ResultSection
                                uploadResult={UPLOAD_RESULT.TOO_LARGE}
                                sectionTitle={t("TOO_LARGE_UPLOADS")}
                                sectionInfo={t("TOO_LARGE_INFO")}
                            />
                        </>
                    )}
                </DialogContent>
            )}
            {uploadPhase == "done" && <UploadProgressFooter />}
        </Dialog>
    );
}
