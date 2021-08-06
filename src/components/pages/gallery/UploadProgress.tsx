import ExpandLess from 'components/icons/ExpandLess';
import ExpandMore from 'components/icons/ExpandMore';
import React, { useEffect, useState } from 'react';
import {
    Alert, Button, Modal, ProgressBar,
} from 'react-bootstrap';
import { FileRejection } from 'react-dropzone';
import { FileUploadResults, UPLOAD_STAGES } from 'services/uploadService';
import styled from 'styled-components';
import { DESKTOP_APP_DOWNLOAD_URL } from 'utils/common';
import constants from 'utils/strings/constants';
import englishConstants from 'utils/strings/englishConstants';

interface Props {
    fileCounter;
    uploadStage;
    now;
    closeModal;
    retryFailed;
    fileProgress: Map<string, number>;
    show;
    fileRejections:FileRejection[]
    uploadResult:Map<string, number>;
}
interface FileProgresses{
    fileName:string;
    progress:number;
}

const FileList =styled.ul<{collapsed:boolean, sm?:boolean}>`
    margin-top: 10px;
    overflow: auto;
    height:${(props)=> props.collapsed?'0px':props.sm?'144px':'200px'};
    transition: height 0.2s ease-out;
`;

const SectionHeader =styled.div`
    display:flex;
    justify-content:space-between;
    padding:0 20px;
    color:#eee;
    font-size:17px;
    cursor:pointer;
`;


export default function UploadProgress(props: Props) {
    const [failedFilesView, setFailedView]=useState(false);
    const [skippedFilesView, setSkippedFilesView]=useState(false);
    const [unsupportedFilesView, setUnsupportedFilesView]=useState(false);
    const [uploadedFilesView, setUploadedFilesView]=useState(false);
    const [blockedFilesView, setBlockedFilesView]=useState(false);

    useEffect(()=>{
        if (props.show) {
            setFailedView(false);
            setSkippedFilesView(false);
            setUnsupportedFilesView(false);
            setUploadedFilesView(false);
            setBlockedFilesView(false);
        }
    }, [props.show]);

    const fileProgressStatuses = [] as FileProgresses[];
    const fileUploadResults = new Map<FileUploadResults, string[]>();
    let filesNotUploaded=false;

    if (props.fileProgress) {
        for (const [fileName, progress] of props.fileProgress) {
            fileProgressStatuses.push({ fileName, progress });
        }
    }
    if (props.uploadResult) {
        for (const [fileName, progress] of props.uploadResult) {
            if (!fileUploadResults.has(progress)) {
                fileUploadResults.set(progress, []);
            }
            if (progress<0) {
                filesNotUploaded=true;
            }
            const fileList= fileUploadResults.get(progress);
            fileUploadResults.set(progress, [...fileList, fileName]);
        }
        // fileUploadResults.set(FileUploadResults.BLOCKED, ['random']);
    }

    return (
        <Modal
            show={props.show}
            onHide={
                props.uploadStage !== UPLOAD_STAGES.FINISH ?
                    () => null :
                    props.closeModal
            }
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop={
                fileProgressStatuses?.length !== 0 ? 'static' : 'true'
            }
        >
            <Modal.Header
                style={{ display: 'flex', justifyContent: 'center', textAlign: 'center', borderBottom: 'none', paddingTop: '30px', paddingBottom: '0px' }}
                closeButton={props.uploadStage === UPLOAD_STAGES.FINISH}
            >

                <h4 style={{ width: '100%' }}>
                    {props.uploadStage === UPLOAD_STAGES.UPLOADING ?
                        constants.UPLOAD[props.uploadStage](
                            props.fileCounter,
                        ) :
                        constants.UPLOAD[props.uploadStage]}
                </h4>
            </Modal.Header>
            <Modal.Body>
                {props.uploadStage===UPLOAD_STAGES.FINISH ? (
                    filesNotUploaded && (
                        <Alert variant="warning">

                            {constants.FILE_NOT_UPLOADED_LIST}
                        </Alert>
                    )
                ) :
                    (props.uploadStage === UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES ||
                        props.uploadStage === UPLOAD_STAGES.UPLOADING) &&
                    (
                        < ProgressBar
                            now={props.now}
                            animated
                            variant="upload-progress-bar"
                        />
                    )
                }
                {fileProgressStatuses.length>0 &&
                <FileList collapsed={false} sm>
                    {fileProgressStatuses.map(({ fileName, progress }) => (
                        <li key={fileName} style={{ marginTop: '12px' }}>
                            {props.uploadStage===UPLOAD_STAGES.FINISH ?
                                fileName :
                                constants.FILE_UPLOAD_PROGRESS(
                                    fileName,
                                    progress,
                                )
                            }
                        </li>
                    ))}
                </FileList>
                }
                {fileUploadResults?.get(FileUploadResults.BLOCKED)?.length>0 &&(<>
                    <SectionHeader onClick={()=>setBlockedFilesView(!blockedFilesView)} > blocked files {blockedFilesView?<ExpandLess/>:<ExpandMore/>}</SectionHeader>
                    <FileList collapsed={!blockedFilesView}>
                        {englishConstants.ETAGS_BLOCKED(DESKTOP_APP_DOWNLOAD_URL)}
                        {fileUploadResults.get(FileUploadResults.BLOCKED).map((fileName) => (

                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {fileName}
                            </li>
                        ))}
                    </FileList>
                </>)}
                {fileUploadResults?.get(FileUploadResults.FAILED)?.length>0 &&(<>
                    <SectionHeader onClick={()=>setFailedView(!failedFilesView)}>{constants.FAILED_FILES} {failedFilesView?<ExpandLess/>:<ExpandMore/>}</SectionHeader>
                    <FileList collapsed={!failedFilesView}>
                        <p> {constants.FAILED_INFO}</p>
                        {fileUploadResults.get(FileUploadResults.FAILED).map((fileName) => (

                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {fileName}
                            </li>
                        ))}
                    </FileList>
                </>)}

                {fileUploadResults?.get(FileUploadResults.SKIPPED)?.length>0 &&(<>
                    <SectionHeader onClick={()=>setSkippedFilesView(!skippedFilesView)}>{constants.SKIPPED_FILES} {skippedFilesView?<ExpandLess/>:<ExpandMore/>}</SectionHeader>
                    <FileList collapsed={!skippedFilesView}>
                        <p>{constants.SKIPPED_INFO}</p>
                        {fileUploadResults.get(FileUploadResults.SKIPPED).map((fileName) => (

                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {fileName}
                            </li>
                        ))}
                    </FileList>
                </>)}

                {fileUploadResults?.get(FileUploadResults.UNSUPPORTED)?.length>0 &&(<>
                    <SectionHeader onClick={()=>setUnsupportedFilesView(!unsupportedFilesView)} >{constants.UNSUPPORTED_FILES}{unsupportedFilesView?<ExpandLess/>:<ExpandMore/>}</SectionHeader>
                    <p>{constants.UNSUPPORTED_INFO}</p>
                    <FileList collapsed={!unsupportedFilesView}>
                        {fileUploadResults.get(FileUploadResults.UNSUPPORTED).map((fileName) => (

                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {fileName}
                            </li>
                        ))}
                    </FileList>
                </>)}

                {fileUploadResults?.get(FileUploadResults.UPLOADED)?.length>0 &&(<>
                    <SectionHeader onClick={()=>setUploadedFilesView(!uploadedFilesView)} > {constants.UPLOADED_FILES} {uploadedFilesView?<ExpandLess/>:<ExpandMore/>}</SectionHeader>
                    <p>{constants.UPLOADED_INFO}</p>
                    <FileList collapsed={!uploadedFilesView}>
                        {fileUploadResults.get(FileUploadResults.UPLOADED).map((fileName) => (

                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {fileName}
                            </li>
                        ))}
                    </FileList>
                </>)}

                {props.uploadStage === UPLOAD_STAGES.FINISH && (
                    <Modal.Footer style={{ border: 'none' }}>
                        {props.uploadStage===UPLOAD_STAGES.FINISH && (fileUploadResults?.get(FileUploadResults.FAILED)?.length>0? (
                            <Button
                                variant="outline-success"
                                style={{ width: '100%' }}
                                onClick={props.retryFailed}
                            >
                                {constants.RETRY_FAILED}
                            </Button>
                        ) : ( <Button
                            variant="outline-secondary"
                            style={{ width: '100%' }}
                            onClick={props.closeModal}
                        >
                            {constants.CLOSE}
                        </Button>
                        ))}
                    </Modal.Footer>
                )}
            </Modal.Body>
        </Modal>
    );
}
