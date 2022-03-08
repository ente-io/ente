import ExpandLess from 'components/icons/ExpandLess';
import ExpandMore from 'components/icons/ExpandMore';
import React, { useState } from 'react';
import { Button, Modal, ProgressBar } from 'react-bootstrap';
import { FileRejection } from 'react-dropzone';

import styled from 'styled-components';
import { DESKTOP_APP_DOWNLOAD_URL } from 'utils/common';
import constants from 'utils/strings/constants';
import { Collapse } from 'react-collapse';
import { ButtonVariant, getVariantColor } from './LinkButton';
import { FileUploadResults, UPLOAD_STAGES } from 'constants/upload';

interface Props {
    fileCounter;
    uploadStage;
    now;
    closeModal;
    retryFailed;
    fileProgress: Map<number, number>;
    filenames: Map<number, string>;
    show;
    fileRejections: FileRejection[];
    uploadResult: Map<number, FileUploadResults>;
    hasLivePhotos: boolean;
}
interface FileProgresses {
    fileID: number;
    progress: number;
}

export const FileList = styled.ul`
    padding-left: 30px;
    margin-top: 5px;
    margin-bottom: 0px;
    & > li {
        padding-left: 5px;
        margin-bottom: 10px;
        color: #ccc;
    }
`;

const SectionTitle = styled.div`
    display: flex;
    justify-content: space-between;
    color: #eee;
    font-size: 20px;
    cursor: pointer;
`;

const Section = styled.div`
    margin: 20px 0;
    & > .ReactCollapse--collapse {
        transition: height 200ms;
    }
    word-break: break-word;
    padding: 0 20px;
`;
const SectionInfo = styled.div`
    margin: 4px 0;
    padding-left: 15px;
`;

const Content = styled.div`
    padding-right: 30px;
`;

const NotUploadSectionHeader = styled.div`
    margin-top: 30px;
    text-align: center;
    color: ${getVariantColor(ButtonVariant.warning)};
    border-bottom: 1px solid ${getVariantColor(ButtonVariant.warning)};
    margin: 0 20px;
`;

interface ResultSectionProps {
    filenames: Map<number, string>;
    fileUploadResultMap: Map<FileUploadResults, number[]>;
    fileUploadResult: FileUploadResults;
    sectionTitle: any;
    sectionInfo?: any;
}
const ResultSection = (props: ResultSectionProps) => {
    const [listView, setListView] = useState(false);
    const fileList = props.fileUploadResultMap?.get(props.fileUploadResult);
    if (!fileList?.length) {
        return <></>;
    }
    return (
        <Section>
            <SectionTitle onClick={() => setListView(!listView)}>
                {props.sectionTitle}
                {listView ? <ExpandLess /> : <ExpandMore />}
            </SectionTitle>
            <Collapse isOpened={listView}>
                <Content>
                    {props.sectionInfo && (
                        <SectionInfo>{props.sectionInfo}</SectionInfo>
                    )}
                    <FileList>
                        {fileList.map((fileID) => (
                            <li key={fileID}>{props.filenames.get(fileID)}</li>
                        ))}
                    </FileList>
                </Content>
            </Collapse>
        </Section>
    );
};

interface InProgressProps {
    filenames: Map<number, string>;
    sectionTitle: string;
    fileProgressStatuses: FileProgresses[];
    sectionInfo?: any;
}
const InProgressSection = (props: InProgressProps) => {
    const [listView, setListView] = useState(true);
    const fileList = props.fileProgressStatuses;
    if (!fileList?.length) {
        return <></>;
    }
    if (!fileList?.length) {
        return <></>;
    }
    return (
        <Section>
            <SectionTitle onClick={() => setListView(!listView)}>
                {props.sectionTitle}
                {listView ? <ExpandLess /> : <ExpandMore />}
            </SectionTitle>
            <Collapse isOpened={listView}>
                <Content>
                    {props.sectionInfo && (
                        <SectionInfo>{props.sectionInfo}</SectionInfo>
                    )}
                    <FileList>
                        {fileList.map(({ fileID, progress }) => (
                            <li key={fileID}>
                                {`${props.filenames.get(
                                    fileID
                                )} - ${progress}%`}
                            </li>
                        ))}
                    </FileList>
                </Content>
            </Collapse>
        </Section>
    );
};

export default function UploadProgress(props: Props) {
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

    return (
        <Modal
            show={props.show}
            onHide={
                props.uploadStage !== UPLOAD_STAGES.FINISH
                    ? () => null
                    : props.closeModal
            }
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop={fileProgressStatuses?.length !== 0 ? 'static' : true}>
            <Modal.Header
                style={{
                    display: 'flex',
                    justifyContent: 'center',
                    textAlign: 'center',
                    borderBottom: 'none',
                    paddingTop: '30px',
                    paddingBottom: '0px',
                }}
                closeButton={props.uploadStage === UPLOAD_STAGES.FINISH}>
                <h4 style={{ width: '100%' }}>
                    {props.uploadStage === UPLOAD_STAGES.UPLOADING
                        ? constants.UPLOAD[props.uploadStage](props.fileCounter)
                        : constants.UPLOAD[props.uploadStage]}
                </h4>
            </Modal.Header>
            <Modal.Body>
                {(props.uploadStage ===
                    UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES ||
                    props.uploadStage === UPLOAD_STAGES.EXTRACTING_METADATA ||
                    props.uploadStage === UPLOAD_STAGES.UPLOADING) && (
                    <ProgressBar
                        now={props.now}
                        animated
                        variant="upload-progress-bar"
                    />
                )}
                <InProgressSection
                    filenames={props.filenames}
                    fileProgressStatuses={fileProgressStatuses}
                    sectionTitle={constants.INPROGRESS_UPLOADS}
                    sectionInfo={sectionInfo}
                />

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
                    fileUploadResult={FileUploadResults.ALREADY_UPLOADED}
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
                    sectionInfo={constants.LARGER_THAN_AVAILABLE_STORAGE_INFO}
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
            </Modal.Body>
            {props.uploadStage === UPLOAD_STAGES.FINISH && (
                <Modal.Footer style={{ border: 'none' }}>
                    {props.uploadStage === UPLOAD_STAGES.FINISH &&
                        (fileUploadResultMap?.get(FileUploadResults.FAILED)
                            ?.length > 0 ||
                        fileUploadResultMap?.get(FileUploadResults.BLOCKED)
                            ?.length > 0 ? (
                            <Button
                                variant="outline-success"
                                style={{ width: '100%' }}
                                onClick={props.retryFailed}>
                                {constants.RETRY_FAILED}
                            </Button>
                        ) : (
                            <Button
                                variant="outline-secondary"
                                style={{ width: '100%' }}
                                onClick={props.closeModal}>
                                {constants.CLOSE}
                            </Button>
                        ))}
                </Modal.Footer>
            )}
        </Modal>
    );
}
