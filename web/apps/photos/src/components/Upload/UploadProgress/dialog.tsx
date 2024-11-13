import { UPLOAD_RESULT } from "@/new/photos/services/upload/types";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    styled,
    type DialogProps,
} from "@mui/material";
import { CaptionedText } from "components/CaptionedText";
import ItemList from "components/ItemList";
import { t } from "i18next";
import React, { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import UploadProgressContext from "./context";
import { UploadProgressHeader } from "./header";
import {
    SectionInfo,
    UploadProgressSection,
    UploadProgressSectionContent,
    UploadProgressSectionTitle,
} from "./section";

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
            {(uploadPhase == "uploading" || uploadPhase == "done") && (
                <DialogContent sx={{ "&&&": { px: 0 } }}>
                    {uploadPhase === "uploading" && <InProgressSection />}
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.UPLOADED}
                        sectionTitle={t("SUCCESSFUL_UPLOADS")}
                    />
                    <ResultSection
                        uploadResult={
                            UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                        }
                        sectionTitle={t("THUMBNAIL_GENERATION_FAILED_UPLOADS")}
                        sectionInfo={t("THUMBNAIL_GENERATION_FAILED_INFO")}
                    />
                    {uploadPhase == "done" && hasUnUploadedFiles && (
                        <NotUploadSectionHeader>
                            {t("FILE_NOT_UPLOADED_LIST")}
                        </NotUploadSectionHeader>
                    )}
                    <ResultSection
                        uploadResult={UPLOAD_RESULT.BLOCKED}
                        sectionTitle={t("BLOCKED_UPLOADS")}
                        sectionInfo={<Trans i18nKey={"ETAGS_BLOCKED"} />}
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
                        sectionInfo={t("LARGER_THAN_AVAILABLE_STORAGE_INFO")}
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
                </DialogContent>
            )}
            {uploadPhase == "done" && <UploadProgressFooter />}
        </Dialog>
    );
}

const InProgressSection: React.FC = () => {
    const { inProgressUploads, hasLivePhotos, uploadFileNames, uploadPhase } =
        useContext(UploadProgressContext);
    const fileList = inProgressUploads ?? [];

    const renderListItem = ({ localFileID, progress }) => {
        return (
            <InProgressItemContainer key={localFileID}>
                <span>{uploadFileNames.get(localFileID)}</span>
                {uploadPhase == "uploading" && (
                    <>
                        {" "}
                        <span className="separator">{`-`}</span>
                        <span>{`${progress}%`}</span>
                    </>
                )}
            </InProgressItemContainer>
        );
    };

    const getItemTitle = ({ localFileID, progress }) => {
        return `${uploadFileNames.get(localFileID)} - ${progress}%`;
    };

    const generateItemKey = ({ localFileID, progress }) => {
        return `${localFileID}-${progress}`;
    };

    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                <CaptionedText
                    mainText={t("INPROGRESS_UPLOADS")}
                    subText={String(inProgressUploads?.length ?? 0)}
                />
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {hasLivePhotos && (
                    <SectionInfo>{t("LIVE_PHOTOS_DETECTED")}</SectionInfo>
                )}
                <ItemList
                    items={fileList}
                    generateItemKey={generateItemKey}
                    getItemTitle={getItemTitle}
                    renderListItem={renderListItem}
                    maxHeight={160}
                    itemSize={35}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};

const InProgressItemContainer = styled("div")`
    display: inline-block;
    & > span {
        display: inline-block;
    }
    & > span:first-of-type {
        position: relative;
        top: 5px;
        max-width: 340px;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }
    & > .separator {
        margin: 0 5px;
    }
`;

const NotUploadSectionHeader = styled("div")(
    ({ theme }) => `
    text-align: center;
    color: ${theme.colors.danger.A700};
    border-bottom: 1px solid ${theme.colors.danger.A700};
    margin:${theme.spacing(3, 2, 1)}
`,
);

const UploadProgressFooter: React.FC = () => {
    const { uploadPhase, finishedUploads, retryFailed, onClose } = useContext(
        UploadProgressContext,
    );

    return (
        <DialogActions>
            {uploadPhase == "done" &&
                (finishedUploads?.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
                finishedUploads?.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ? (
                    <Button variant="contained" fullWidth onClick={retryFailed}>
                        {t("RETRY_FAILED")}
                    </Button>
                ) : (
                    <Button variant="contained" fullWidth onClick={onClose}>
                        {t("close")}
                    </Button>
                ))}
        </DialogActions>
    );
};

interface ResultSectionProps {
    uploadResult: UPLOAD_RESULT;
    sectionTitle: any;
    sectionInfo?: any;
}

const ResultSection = (props: ResultSectionProps) => {
    const { finishedUploads, uploadFileNames } = useContext(
        UploadProgressContext,
    );
    const fileList = finishedUploads.get(props.uploadResult);

    if (!fileList?.length) {
        return <></>;
    }

    const renderListItem = (fileID) => {
        return (
            <ResultItemContainer key={fileID}>
                {uploadFileNames.get(fileID)}
            </ResultItemContainer>
        );
    };

    const getItemTitle = (fileID) => {
        return uploadFileNames.get(fileID);
    };

    const generateItemKey = (fileID) => {
        return fileID;
    };

    return (
        <UploadProgressSection>
            <UploadProgressSectionTitle expandIcon={<ExpandMoreIcon />}>
                <CaptionedText
                    mainText={props.sectionTitle}
                    subText={String(fileList?.length ?? 0)}
                />
            </UploadProgressSectionTitle>
            <UploadProgressSectionContent>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <ItemList
                    items={fileList}
                    generateItemKey={generateItemKey}
                    getItemTitle={getItemTitle}
                    renderListItem={renderListItem}
                    maxHeight={160}
                    itemSize={35}
                />
            </UploadProgressSectionContent>
        </UploadProgressSection>
    );
};

const ResultItemContainer = styled("div")`
    position: relative;
    top: 5px;
    display: inline-block;
    max-width: 394px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
`;
