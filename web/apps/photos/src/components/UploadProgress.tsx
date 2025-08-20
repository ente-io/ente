// TODO: Audit this file
/* eslint-disable @typescript-eslint/no-unsafe-argument */
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
    Tooltip,
    Typography,
    type AccordionProps,
    type DialogProps,
} from "@mui/material";
import { SpacedRow } from "ente-base/components/containers";
import { FilledIconButton } from "ente-base/components/mui";
import { useBaseContext } from "ente-base/context";
import { formattedListJoin } from "ente-base/i18n";
import { type UploadPhase } from "ente-gallery/services/upload";
import { t } from "i18next";
import memoize from "memoize-one";
import React, {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useState,
    type ReactElement,
} from "react";
import { Trans } from "react-i18next";
import {
    areEqual,
    FixedSizeList as List,
    type ListChildComponentProps,
    type ListItemKeySelector,
} from "react-window";
import type {
    FinishedUploadType,
    InProgressUpload,
    SegregatedFinishedUploads,
    UploadCounter,
    UploadFileNames,
} from "services/upload-manager";

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

    const handleClose = useCallback(() => {
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
    }, [uploadPhase, onClose, cancelUploads, showMiniDialog]);

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

/**
 * A context internal to the components of this file.
 */
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

const UploadProgressContext = createContext<UploadProgressContextT | undefined>(
    undefined,
);

/**
 * Convenience hook to obtain the non-null asserted
 * {@link UploadProgressContext}.
 *
 * The non-null assertion is reasonable since we provide it to the tree always
 * in an invariant that is local to this file (and thus has less chance of being
 * invalid in the future).
 */
const useUploadProgressContext = () => useContext(UploadProgressContext)!;

const MinimizedUploadProgress: React.FC = () => (
    <Snackbar open anchorOrigin={{ horizontal: "right", vertical: "bottom" }}>
        <Paper sx={{ width: "min(360px, 100svw)" }}>
            <UploadProgressHeader />
        </Paper>
    </Snackbar>
);

const UploadProgressHeader: React.FC = () => (
    <>
        <UploadProgressTitle />
        <UploadProgressBar />
    </>
);

const UploadProgressTitle: React.FC = () => {
    const { setExpanded, onClose, expanded } = useUploadProgressContext();
    const toggleExpanded = () => setExpanded((expanded) => !expanded);

    return (
        <DialogTitle>
            <SpacedRow>
                <Box>
                    <Typography variant="h3">{t("file_upload")}</Typography>
                    <UploadProgressSubtitleText />
                </Box>
                <Stack direction="row" sx={{ gap: 1 }}>
                    <FilledIconButton onClick={toggleExpanded}>
                        {expanded ? <UnfoldLessIcon /> : <UnfoldMoreIcon />}
                    </FilledIconButton>
                    <FilledIconButton onClick={onClose}>
                        <CloseIcon />
                    </FilledIconButton>
                </Stack>
            </SpacedRow>
        </DialogTitle>
    );
};

const UploadProgressSubtitleText: React.FC = () => {
    const { uploadPhase, uploadCounter, finishedUploads } =
        useUploadProgressContext();

    return (
        <Typography
            variant="body"
            sx={{
                fontWeight: "regular",
                color: "text.muted",
                marginTop: "4px",
            }}
        >
            {subtitleText(uploadPhase, uploadCounter, finishedUploads)}
        </Typography>
    );
};

const subtitleText = (
    uploadPhase: UploadPhase,
    uploadCounter: UploadCounter,
    finishedUploads: SegregatedFinishedUploads | null | undefined,
) => {
    switch (uploadPhase) {
        case "preparing":
            return t("preparing");
        case "readingMetadata":
            return t("upload_reading_metadata_files");
        case "uploading":
            return t("processed_counts", {
                count: uploadCounter.finished,
                total: uploadCounter.total,
            });
        case "cancelling":
            return t("upload_cancelling");
        case "done": {
            const count = uploadedFileCount(finishedUploads);
            const notCount = notUploadedFileCount(finishedUploads);
            const items: string[] = [];
            if (count) items.push(t("upload_done", { count }));
            if (notCount) items.push(t("upload_skipped", { count: notCount }));
            if (!items.length) {
                return t("upload_done", { count });
            } else {
                return formattedListJoin(items);
            }
        }
    }
};

const uploadedFileCount = (
    finishedUploads: SegregatedFinishedUploads | null | undefined,
) => {
    if (!finishedUploads) return 0;

    let c = 0;
    c += finishedUploads.get("uploaded")?.length ?? 0;
    c += finishedUploads.get("uploadedWithStaticThumbnail")?.length ?? 0;

    return c;
};

const notUploadedFileCount = (
    finishedUploads: SegregatedFinishedUploads | null | undefined,
) => {
    if (!finishedUploads) return 0;

    let c = 0;
    c += finishedUploads.get("alreadyUploaded")?.length ?? 0;
    c += finishedUploads.get("blocked")?.length ?? 0;
    c += finishedUploads.get("failed")?.length ?? 0;
    c += finishedUploads.get("largerThanAvailableStorage")?.length ?? 0;
    c += finishedUploads.get("tooLarge")?.length ?? 0;
    c += finishedUploads.get("unsupported")?.length ?? 0;
    return c;
};

const UploadProgressBar: React.FC = () => {
    const { uploadPhase, percentComplete } = useUploadProgressContext();

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
    const { open, onClose, uploadPhase, finishedUploads } =
        useUploadProgressContext();

    const [hasUnUploadedFiles, setHasUnUploadedFiles] = useState(false);

    useEffect(() => {
        setHasUnUploadedFiles(notUploadedFileCount(finishedUploads) > 0);
    }, [finishedUploads]);

    const handleClose: DialogProps["onClose"] = (_, reason) => {
        if (reason != "backdropClick") onClose();
    };

    return (
        <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
            <UploadProgressHeader />
            {(uploadPhase == "uploading" || uploadPhase == "done") && (
                <DialogContent sx={{ "&&&": { px: 0 } }}>
                    {uploadPhase == "uploading" && <InProgressSection />}
                    <ResultSection
                        resultType="uploaded"
                        sectionTitle={t("successful_uploads")}
                    />
                    <ResultSection
                        resultType="uploadedWithStaticThumbnail"
                        sectionTitle={t("thumbnail_generation_failed")}
                        sectionInfo={t("thumbnail_generation_failed_hint")}
                    />
                    {uploadPhase == "done" && hasUnUploadedFiles && (
                        <NotUploadSectionHeader>
                            {t("file_not_uploaded_list")}
                        </NotUploadSectionHeader>
                    )}
                    <ResultSection
                        resultType="blocked"
                        sectionTitle={t("blocked_uploads")}
                        sectionInfo={<Trans i18nKey={"blocked_uploads_hint"} />}
                    />
                    <ResultSection
                        resultType="failed"
                        sectionTitle={t("failed_uploads")}
                        sectionInfo={
                            uploadPhase == "done"
                                ? undefined
                                : t("failed_uploads_hint")
                        }
                    />
                    <ResultSection
                        resultType="alreadyUploaded"
                        sectionTitle={t("ignored_uploads")}
                        sectionInfo={t("ignored_uploads_hint")}
                    />
                    <ResultSection
                        resultType="largerThanAvailableStorage"
                        sectionTitle={t("insufficient_storage")}
                        sectionInfo={t("insufficient_storage_hint")}
                    />
                    <ResultSection
                        resultType="unsupported"
                        sectionTitle={t("unsupported_files")}
                        sectionInfo={t("unsupported_files_hint")}
                    />
                    <ResultSection
                        resultType="tooLarge"
                        sectionTitle={t("large_files")}
                        sectionInfo={t("large_files_hint")}
                    />
                </DialogContent>
            )}
            {uploadPhase == "done" && <DoneFooter />}
        </Dialog>
    );
}

const InProgressSection: React.FC = () => {
    const { inProgressUploads, hasLivePhotos, uploadFileNames, uploadPhase } =
        useUploadProgressContext();

    const fileList = inProgressUploads;

    // @ts-expect-error Need to add types
    const renderListItem = ({ localFileID, progress }) => {
        return (
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
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

    // @ts-expect-error Need to add types
    const getItemTitle = ({ localFileID, progress }) => {
        return `${uploadFileNames.get(localFileID)} - ${progress}%`;
    };

    // @ts-expect-error Need to add types
    const generateItemKey = ({ localFileID, progress }) => {
        return `${localFileID}-${progress}`;
    };

    return (
        <SectionAccordion>
            <SectionAccordionSummary expandIcon={<ExpandMoreIcon />}>
                <TitleText
                    title={t("uploads_in_progress")}
                    count={inProgressUploads.length}
                />
            </SectionAccordionSummary>
            <SectionAccordionDetails>
                {hasLivePhotos && (
                    <SectionInfo>{t("live_photos_detected")}</SectionInfo>
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
    resultType: FinishedUploadType;
    sectionTitle: string;
    sectionInfo?: React.ReactNode;
}

const ResultSection: React.FC<ResultSectionProps> = ({
    resultType,
    sectionTitle,
    sectionInfo,
}) => {
    const { finishedUploads, uploadFileNames } = useUploadProgressContext();

    const fileList = finishedUploads.get(resultType);

    if (!fileList?.length) {
        return <></>;
    }

    // @ts-expect-error Need to add types
    const renderListItem = (fileID) => {
        return (
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
            <ResultItemContainer key={fileID}>
                {uploadFileNames.get(fileID)}
            </ResultItemContainer>
        );
    };

    // @ts-expect-error Need to add types
    const getItemTitle = (fileID) => {
        return uploadFileNames.get(fileID)!;
    };

    // @ts-expect-error Need to add types
    const generateItemKey = (fileID) => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-return
        return fileID;
    };

    return (
        <SectionAccordion>
            <SectionAccordionSummary expandIcon={<ExpandMoreIcon />}>
                <TitleText title={sectionTitle} count={fileList.length} />
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

interface ItemListProps<T> {
    items: T[];
    generateItemKey: (item: T) => string | number;
    getItemTitle: (item: T) => string;
    renderListItem: (item: T) => React.JSX.Element;
    maxHeight?: number;
    itemSize?: number;
}

interface ItemData<T> {
    renderListItem: (item: T) => React.JSX.Element;
    getItemTitle: (item: T) => string;
    items: T[];
}

const createItemData: <T>(
    renderListItem: (item: T) => React.JSX.Element,
    getItemTitle: (item: T) => string,
    items: T[],
) => ItemData<T> = memoize((renderListItem, getItemTitle, items) => ({
    // TODO
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    renderListItem,
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    getItemTitle,
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    items,
}));

// TODO: Too many non-null assertions

// @ts-expect-error "TODO: Understand and fix the type error here"
const Row: <T>({
    index,
    style,
    data,
}: ListChildComponentProps<ItemData<T>>) => ReactElement = React.memo(
    ({ index, style, data }) => {
        const { renderListItem, items, getItemTitle } = data;
        return (
            <Tooltip
                slotProps={{
                    // Reduce the vertical offset of the tooltip "popper" from
                    // the element on which the tooltip appears.
                    popper: {
                        modifiers: [
                            { name: "offset", options: { offset: [0, -14] } },
                        ],
                    },
                }}
                title={getItemTitle(items[index]!)}
                placement="bottom-start"
                enterDelay={300}
                enterNextDelay={100}
            >
                <div style={style}>{renderListItem(items[index]!)}</div>
            </Tooltip>
        );
    },
    areEqual,
);

function ItemList<T>(props: ItemListProps<T>) {
    const itemData = createItemData(
        props.renderListItem,
        props.getItemTitle,
        props.items,
    );

    const getItemKey: ListItemKeySelector<ItemData<T>> = (index, data) => {
        const { items } = data;
        return props.generateItemKey(items[index]!);
    };

    return (
        <Box sx={{ pl: 2 }}>
            <List
                itemData={itemData}
                height={Math.min(
                    props.itemSize! * props.items.length,
                    props.maxHeight!,
                )}
                width={"100%"}
                itemSize={props.itemSize!}
                itemCount={props.items.length}
                itemKey={getItemKey}
            >
                {Row}
            </List>
        </Box>
    );
}

const DoneFooter: React.FC = () => {
    const { uploadPhase, finishedUploads, retryFailed, onClose } =
        useUploadProgressContext();

    return (
        <DialogActions>
            {uploadPhase == "done" &&
                ((finishedUploads.get("failed")?.length ?? 0) > 0 ||
                (finishedUploads.get("blocked")?.length ?? 0) > 0 ? (
                    <Button fullWidth onClick={retryFailed}>
                        {t("retry_failed_uploads")}
                    </Button>
                ) : (
                    <Button fullWidth onClick={onClose}>
                        {t("close")}
                    </Button>
                ))}
        </DialogActions>
    );
};
