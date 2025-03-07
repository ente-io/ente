import { FilledIconButton } from "@/base/components/mui";
import { useBaseContext } from "@/base/context";
import { UPLOAD_RESULT, type UploadPhase } from "@/gallery/services/upload";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import UnfoldLessIcon from "@mui/icons-material/UnfoldLess";
import UnfoldMoreIcon from "@mui/icons-material/UnfoldMore";
import {
    Accordion,
    AccordionDetails,
    AccordionSummary,
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    LinearProgress,
    Paper,
    Snackbar,
    Stack,
    styled,
    Typography,
    type AccordionProps,
    type DialogProps,
} from "@mui/material";
import ItemList from "components/ItemList";
import { t } from "i18next";
import React, { createContext, useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import type {
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "services/upload/uploadManager";

interface UploadProgressProps {
    open: boolean;
    onClose: () => void;
    uploadCounter: UploadCounter;
    uploadPhase: UploadPhase;
    percentComplete: number;
    retryFailed: () => void;
    inProgressUploads: InProgressUpload[];
    uploadFileNames: UploadFileNames;
    finishedUploads: SegregatedFinishedUploads;
    hasLivePhotos: boolean;
    cancelUploads: () => void;
}

export const UploadProgress: React.FC<UploadProgressProps> = ({
    open,
    onClose,
    uploadCounter,
    uploadPhase,
    percentComplete,
    retryFailed,
    uploadFileNames,
    hasLivePhotos,
    inProgressUploads,
    finishedUploads,
    cancelUploads,
}) => {
    const { showMiniDialog } = useBaseContext();

    const [expanded, setExpanded] = useState(false);

    useEffect(() => {
        if (open) setExpanded(false);
    }, [open]);

    const handleClose = () => {
        if (uploadPhase == "done") {
            onClose();
        } else {
            showMiniDialog({
                title: t("stop_uploads_title"),
                message: t("stop_uploads_message"),
                continue: {
                    text: t("yes_stop_uploads"),
                    color: "critical",
                    action: cancelUploads,
                },
                cancel: t("no"),
            });
        }
    };

    if (!open) {
        return <></>;
    }

    return (
        <UploadProgressContext.Provider
            value={{
                open,
                onClose: handleClose,
                uploadCounter,
                uploadPhase,
                percentComplete,
                retryFailed,
                inProgressUploads,
                uploadFileNames,
                finishedUploads,
                hasLivePhotos,
                expanded,
                setExpanded,
            }}
        >
            {expanded ? <UploadProgressDialog /> : <MinimizedUploadProgress />}
        </UploadProgressContext.Provider>
    );
};

interface UploadProgressContextT {
    open: boolean;
    onClose: () => void;
    uploadCounter: UploadCounter;
    uploadPhase: UploadPhase;
    percentComplete: number;
    retryFailed: () => void;
    inProgressUploads: InProgressUpload[];
    uploadFileNames: UploadFileNames;
    finishedUploads: SegregatedFinishedUploads;
    hasLivePhotos: boolean;
    expanded: boolean;
    setExpanded: React.Dispatch<React.SetStateAction<boolean>>;
}

const UploadProgressContext = createContext<UploadProgressContextT>({
    open: null,
    onClose: () => null,
    uploadCounter: null,
    uploadPhase: undefined,
    percentComplete: null,
    retryFailed: () => null,
    inProgressUploads: null,
    uploadFileNames: null,
    finishedUploads: null,
    hasLivePhotos: null,
    expanded: null,
    setExpanded: () => null,
});

const MinimizedUploadProgress: React.FC = () => (
    <Snackbar
        open
        anchorOrigin={{ horizontal: "right", vertical: "bottom" }}
        sx={(theme) => ({ boxShadow: theme.vars.palette.boxShadow.menu })}
    >
        <Paper sx={{ width: "min(360px, 100svw)" }}>
            <UploadProgressHeader />
        </Paper>
    </Snackbar>
);

function UploadProgressHeader() {
    return (
        <>
            <UploadProgressTitle />
            <UploadProgressBar />
        </>
    );
}

const UploadProgressTitleText = ({ expanded }) => {
    return (
        <Typography variant={expanded ? "h2" : "h3"}>
            {t("FILE_UPLOAD")}
        </Typography>
    );
};

function UploadProgressSubtitleText() {
    const { uploadPhase, uploadCounter } = useContext(UploadProgressContext);

    return (
        <Typography
            variant="body"
            sx={{
                fontWeight: "regular",
                color: "text.muted",
                marginTop: "4px",
            }}
        >
            {subtitleText(uploadPhase, uploadCounter)}
        </Typography>
    );
}

const subtitleText = (
    uploadPhase: UploadPhase,
    uploadCounter: UploadCounter,
) => {
    switch (uploadPhase) {
        case "preparing":
            return t("UPLOAD_STAGE_MESSAGE.0");
        case "readingMetadata":
            return t("UPLOAD_STAGE_MESSAGE.1");
        case "uploading":
            return t("UPLOAD_STAGE_MESSAGE.3", { uploadCounter });
        case "cancelling":
            return t("UPLOAD_STAGE_MESSAGE.4");
        case "done":
            return t("UPLOAD_STAGE_MESSAGE.5");
    }
};

const UploadProgressTitle: React.FC = () => {
    const { setExpanded, onClose, expanded } = useContext(
        UploadProgressContext,
    );
    const toggleExpanded = () => setExpanded((expanded) => !expanded);

    return (
        <DialogTitle>
            <SpaceBetweenFlex>
                <Box>
                    <UploadProgressTitleText expanded={expanded} />
                    <UploadProgressSubtitleText />
                </Box>
                <Box>
                    <Stack direction="row" sx={{ gap: 1 }}>
                        <FilledIconButton onClick={toggleExpanded}>
                            {expanded ? <UnfoldLessIcon /> : <UnfoldMoreIcon />}
                        </FilledIconButton>
                        <FilledIconButton onClick={onClose}>
                            <CloseIcon />
                        </FilledIconButton>
                    </Stack>
                </Box>
            </SpaceBetweenFlex>
        </DialogTitle>
    );
};

const UploadProgressBar: React.FC = () => {
    const { uploadPhase, percentComplete } = useContext(UploadProgressContext);
    return (
        <Box>
            {(uploadPhase == "readingMetadata" ||
                uploadPhase == "uploading") && (
                <>
                    <LinearProgress
                        sx={{ height: "2px", backgroundColor: "transparent" }}
                        variant="determinate"
                        value={percentComplete}
                    />
                    <Divider />
                </>
            )}
        </Box>
    );
};

function UploadProgressDialog() {
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
            {uploadPhase == "done" && <DoneFooter />}
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
        <SectionAccordion>
            <SectionAccordionSummary expandIcon={<ExpandMoreIcon />}>
                <TitleText
                    title={t("INPROGRESS_UPLOADS")}
                    count={inProgressUploads?.length}
                />
            </SectionAccordionSummary>
            <SectionAccordionDetails>
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
            </SectionAccordionDetails>
        </SectionAccordion>
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

const SectionAccordion = styled((props: AccordionProps) => (
    <Accordion disableGutters elevation={0} square {...props} />
))(({ theme }) => ({
    borderTop: `1px solid ${theme.vars.palette.divider}`,
    "&:before": { display: "none" },
    "&:last-child": { borderBottom: `1px solid ${theme.vars.palette.divider}` },
}));

const SectionAccordionSummary = styled(AccordionSummary)(({ theme }) => ({
    backgroundColor: theme.vars.palette.fill.fainter,
    // AccordionSummary is a button, and for a reasons to do with MUI internal
    // that I didn't explore further, the user agent default font family is
    // getting applied in this case.
    fontFamily: "inherit",
}));

const SectionAccordionDetails = styled(AccordionDetails)(({ theme }) => ({
    padding: theme.spacing(2),
}));

const SectionInfo: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Typography variant="small" sx={{ color: "text.muted", mb: 1 }}>
        {children}
    </Typography>
);

const NotUploadSectionHeader = styled("div")(
    ({ theme }) => `
    text-align: center;
    color: ${theme.vars.palette.critical.main};
    border-bottom: 1px solid ${theme.vars.palette.critical.main};
    margin:${theme.spacing(3, 2, 1)}
`,
);

interface ResultSectionProps {
    uploadResult: UPLOAD_RESULT;
    sectionTitle: string;
    sectionInfo?: React.ReactNode;
}

const ResultSection: React.FC<ResultSectionProps> = ({
    uploadResult,
    sectionTitle,
    sectionInfo,
}) => {
    const { finishedUploads, uploadFileNames } = useContext(
        UploadProgressContext,
    );
    const fileList = finishedUploads.get(uploadResult);

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
        <SectionAccordion>
            <SectionAccordionSummary expandIcon={<ExpandMoreIcon />}>
                <TitleText title={sectionTitle} count={fileList?.length} />
            </SectionAccordionSummary>
            <SectionAccordionDetails>
                {sectionInfo && <SectionInfo>{sectionInfo}</SectionInfo>}
                <ItemList
                    items={fileList}
                    generateItemKey={generateItemKey}
                    getItemTitle={getItemTitle}
                    renderListItem={renderListItem}
                    maxHeight={160}
                    itemSize={35}
                />
            </SectionAccordionDetails>
        </SectionAccordion>
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

interface TitleTextProps {
    title: string;
    count: number | undefined;
}

const TitleText: React.FC<TitleTextProps> = ({ title, count }) => (
    <Stack
        direction="row"
        // Need to reset the font weight since it gets reset by the
        // AccordionSummary (see SectionAccordionSummary).
        sx={{ gap: 1, fontWeight: "regular", alignItems: "baseline" }}
    >
        <Typography>{title}</Typography>
        <Typography variant="small" sx={{ color: "text.faint" }}>
            {"•"}
        </Typography>
        <Typography variant="small" sx={{ color: "text.faint" }}>
            {count ?? 0}
        </Typography>
    </Stack>
);

const DoneFooter: React.FC = () => {
    const { uploadPhase, finishedUploads, retryFailed, onClose } = useContext(
        UploadProgressContext,
    );

    return (
        <DialogActions>
            {uploadPhase == "done" &&
                (finishedUploads?.get(UPLOAD_RESULT.FAILED)?.length > 0 ||
                finishedUploads?.get(UPLOAD_RESULT.BLOCKED)?.length > 0 ? (
                    <Button fullWidth onClick={retryFailed}>
                        {t("RETRY_FAILED")}
                    </Button>
                ) : (
                    <Button fullWidth onClick={onClose}>
                        {t("close")}
                    </Button>
                ))}
        </DialogActions>
    );
};
