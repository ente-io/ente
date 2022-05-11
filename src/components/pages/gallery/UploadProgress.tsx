/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useContext, useState } from 'react';

import styled from 'styled-components';
import { DESKTOP_APP_DOWNLOAD_URL } from 'utils/common';
import constants from 'utils/strings/constants';
import { ButtonVariant, getVariantColor } from './LinkButton';
import { FileUploadResults, UPLOAD_STAGES } from 'constants/upload';
import FileList from 'components/FileList';
import { AppContext } from 'pages/_app';
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
    IconButton,
    LinearProgress,
    Typography,
} from '@mui/material';
import { FlexWrapper, SpaceBetweenFlex } from 'components/Container';
import Close from '@mui/icons-material/Close';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import OpenInFullIcon from '@mui/icons-material/OpenInFull';
import CloseFullscreenIcon from '@mui/icons-material/CloseFullscreen';
interface Props {
    fileCounter;
    uploadStage;
    now;
    closeModal;
    retryFailed;
    fileProgress: Map<number, number>;
    filenames: Map<number, string>;
    show;
    uploadResult: Map<number, FileUploadResults>;
    hasLivePhotos: boolean;
    cancelUploads: () => void;
}
interface FileProgresses {
    fileID: number;
    progress: number;
}

const SectionTitle = styled.div`
    display: flex;
    justify-content: space-between;
    color: #eee;
    font-size: 20px;
    cursor: pointer;
`;

const Section = styled.div`
    margin: 20px 0;
    padding: 0 20px;
`;
const SectionInfo = styled.div`
    margin: 4px 0;
    padding-left: 15px;
`;

const SectionContent = styled.div`
    padding-right: 35px;
`;

const NotUploadSectionHeader = styled.div`
    margin-top: 30px;
    text-align: center;
    color: ${getVariantColor(ButtonVariant.warning)};
    border-bottom: 1px solid ${getVariantColor(ButtonVariant.warning)};
    margin: 0 20px;
`;

const InProgressItemContainer = styled.div`
    display: inline-block;
    & > span {
        display: inline-block;
    }
    & > span:first-of-type {
        position: relative;
        top: 5px;
        max-width: 287px;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }
    & > .separator {
        margin: 0 5px;
    }
`;

const ResultItemContainer = styled.div`
    position: relative;
    top: 5px;
    display: inline-block;
    max-width: 334px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
`;

interface ResultSectionProps {
    filenames: Map<number, string>;
    fileUploadResultMap: Map<FileUploadResults, number[]>;
    fileUploadResult: FileUploadResults;
    sectionTitle: any;
    sectionInfo?: any;
}
const ResultSection = (props: ResultSectionProps) => {
    const fileList = props.fileUploadResultMap?.get(props.fileUploadResult);
    if (!fileList?.length) {
        return <></>;
    }
    return (
        <Accordion>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography> {props.sectionTitle}</Typography>
            </AccordionSummary>
            <AccordionDetails>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <FileList
                    fileList={fileList.map((fileID) => (
                        <ResultItemContainer key={fileID}>
                            {props.filenames.get(fileID)}
                        </ResultItemContainer>
                    ))}
                />
            </AccordionDetails>
        </Accordion>
    );
};

interface InProgressProps {
    filenames: Map<number, string>;
    sectionTitle: string;
    fileProgressStatuses: FileProgresses[];
    sectionInfo?: any;
}
const InProgressSection = (props: InProgressProps) => {
    const fileList = props.fileProgressStatuses ?? [];

    return (
        <Accordion>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                {props.sectionTitle}
            </AccordionSummary>
            <AccordionDetails>
                {props.sectionInfo && (
                    <SectionInfo>{props.sectionInfo}</SectionInfo>
                )}
                <FileList
                    fileList={fileList.map(({ fileID, progress }) => (
                        <InProgressItemContainer key={fileID}>
                            <span>{props.filenames.get(fileID)}</span>
                            <span className="separator">{`-`}</span>
                            <span>{`${progress}%`}</span>
                        </InProgressItemContainer>
                    ))}
                />
            </AccordionDetails>
        </Accordion>
    );
};

export default function UploadProgress(props: Props) {
    const appContext = useContext(AppContext);
    const [expanded, setExpanded] = useState(true);
    const fileProgressStatuses = [] as FileProgresses[];
    const fileUploadResultMap = new Map<FileUploadResults, number[]>();
    let filesNotUploaded = false;
    let sectionInfo = null;
    if (props.fileProgress) {
        for (const [localID, progress] of props.fileProgress) {
            fileProgressStatuses.push({
                fileID: localID,
                progress,
            });
        }
    }
    if (props.uploadResult) {
        for (const [localID, progress] of props.uploadResult) {
            if (!fileUploadResultMap.has(progress)) {
                fileUploadResultMap.set(progress, []);
            }
            if (progress !== FileUploadResults.UPLOADED) {
                filesNotUploaded = true;
            }
            const fileList = fileUploadResultMap.get(progress);

            fileUploadResultMap.set(progress, [...fileList, localID]);
        }
    }
    if (props.hasLivePhotos) {
        sectionInfo = constants.LIVE_PHOTOS_DETECTED();
    }

    function handleHideModal() {
        if (props.uploadStage !== UPLOAD_STAGES.FINISH) {
            appContext.setDialogMessage({
                title: constants.STOP_UPLOADS_HEADER,
                content: constants.STOP_ALL_UPLOADS_MESSAGE,
                proceed: {
                    text: constants.YES_STOP_UPLOADS,
                    variant: 'danger',
                    action: props.cancelUploads,
                },
                close: {
                    text: constants.NO,
                    variant: 'secondary',
                    action: () => {},
                },
            });
        } else {
            props.closeModal();
        }
    }
    return (
        <>
            <Dialog
                maxWidth="xs"
                fullWidth
                open={props.show}
                sx={
                    !expanded && {
                        '& .MuiDialog-container': {
                            alignItems: 'flex-end',
                            justifyContent: 'flex-end',
                        },
                    }
                }
                onClose={handleHideModal}>
                <DialogTitle>
                    <SpaceBetweenFlex>
                        <Box>
                            <Typography variant="h5">
                                {constants.FILE_UPLOAD}
                            </Typography>
                            <Typography
                                variant="subtitle1"
                                color="text.secondary">
                                {props.uploadStage === UPLOAD_STAGES.UPLOADING
                                    ? constants.UPLOAD_STAGE_MESSAGE[
                                          props.uploadStage
                                      ](props.fileCounter)
                                    : constants.UPLOAD_STAGE_MESSAGE[
                                          props.uploadStage
                                      ]}
                            </Typography>
                        </Box>
                        <Box>
                            <FlexWrapper>
                                <IconButton
                                    onClick={() => setExpanded((e) => !e)}
                                    sx={{
                                        m: 0.5,
                                        backgroundColor: (theme) =>
                                            theme.palette.secondary.main,
                                    }}>
                                    {expanded ? (
                                        <CloseFullscreenIcon
                                            sx={{
                                                padding: '4px',
                                                transform: 'rotate(90deg)',
                                            }}
                                        />
                                    ) : (
                                        <OpenInFullIcon
                                            sx={{
                                                padding: '4px',
                                                transform: 'rotate(90deg)',
                                            }}
                                        />
                                    )}
                                </IconButton>
                                <IconButton
                                    onClick={handleHideModal}
                                    sx={{
                                        m: 0.5,
                                        backgroundColor: (theme) =>
                                            theme.palette.secondary.main,
                                    }}>
                                    <Close />
                                </IconButton>
                            </FlexWrapper>
                        </Box>
                    </SpaceBetweenFlex>
                </DialogTitle>
                {(props.uploadStage ===
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES ||
                    props.uploadStage === UPLOAD_STAGES.EXTRACTING_METADATA ||
                    props.uploadStage === UPLOAD_STAGES.UPLOADING) && (
                    <LinearProgress
                        sx={{
                            height: '2px',
                            backgroundColor: 'transparent',
                        }}
                        color="negative"
                        variant="determinate"
                        value={props.now}
                    />
                )}
                <Divider />
                {expanded && (
                    <DialogContent
                        sx={{
                            px: 0,
                            '& .paper-root': { borderRadius: 0 },
                        }}>
                        {props.uploadStage === UPLOAD_STAGES.UPLOADING && (
                            <InProgressSection
                                filenames={props.filenames}
                                fileProgressStatuses={fileProgressStatuses}
                                sectionTitle={constants.INPROGRESS_UPLOADS}
                                sectionInfo={sectionInfo}
                            />
                        )}

                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={FileUploadResults.UPLOADED}
                            sectionTitle={constants.SUCCESSFUL_UPLOADS}
                        />

                        {props.uploadStage === UPLOAD_STAGES.FINISH &&
                            filesNotUploaded && (
                                <NotUploadSectionHeader>
                                    {constants.FILE_NOT_UPLOADED_LIST}
                                </NotUploadSectionHeader>
                            )}

                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={FileUploadResults.BLOCKED}
                            sectionTitle={constants.BLOCKED_UPLOADS}
                            sectionInfo={constants.ETAGS_BLOCKED(
                                DESKTOP_APP_DOWNLOAD_URL
                            )}
                        />
                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={FileUploadResults.FAILED}
                            sectionTitle={constants.FAILED_UPLOADS}
                        />
                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={
                                FileUploadResults.ALREADY_UPLOADED
                            }
                            sectionTitle={constants.SKIPPED_FILES}
                            sectionInfo={constants.SKIPPED_INFO}
                        />
                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={
                                FileUploadResults.LARGER_THAN_AVAILABLE_STORAGE
                            }
                            sectionTitle={
                                constants.LARGER_THAN_AVAILABLE_STORAGE_UPLOADS
                            }
                            sectionInfo={
                                constants.LARGER_THAN_AVAILABLE_STORAGE_INFO
                            }
                        />
                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={FileUploadResults.UNSUPPORTED}
                            sectionTitle={constants.UNSUPPORTED_FILES}
                            sectionInfo={constants.UNSUPPORTED_INFO}
                        />
                        <ResultSection
                            filenames={props.filenames}
                            fileUploadResultMap={fileUploadResultMap}
                            fileUploadResult={FileUploadResults.TOO_LARGE}
                            sectionTitle={constants.TOO_LARGE_UPLOADS}
                            sectionInfo={constants.TOO_LARGE_INFO}
                        />
                    </DialogContent>
                )}
                {props.uploadStage === UPLOAD_STAGES.FINISH && (
                    <DialogActions>
                        {props.uploadStage === UPLOAD_STAGES.FINISH &&
                            (fileUploadResultMap?.get(FileUploadResults.FAILED)
                                ?.length > 0 ||
                            fileUploadResultMap?.get(FileUploadResults.BLOCKED)
                                ?.length > 0 ? (
                                <Button
                                    variant="contained"
                                    fullWidth
                                    onClick={props.retryFailed}>
                                    {constants.RETRY_FAILED}
                                </Button>
                            ) : (
                                <Button
                                    variant="contained"
                                    fullWidth
                                    onClick={props.closeModal}>
                                    {constants.CLOSE}
                                </Button>
                            ))}
                    </DialogActions>
                )}
            </Dialog>
        </>
    );
}
