import { Modal, Button } from 'react-bootstrap';
import React from 'react';
import ImportService from 'services/importService';
import { getElectronFiles } from 'utils/upload';
import constants from 'utils/strings/constants';
import { IoIosArrowForward, IoMdClose } from 'react-icons/io';
import styled from 'styled-components';

const LeftAlignedDiv = styled.div`
    float: left;
    display: flex;
    gap: 0.8em;
    justify-content: center;
    align-items: center;
`;

const RightAlignedDiv = styled.div`
    float: right;
    position: relative;
    top: 50%;
    transform: translateY(-50%);
`;

export default function FileTypeChoiceModal({
    setElectronFiles,
    showFiletypeModal,
    setShowFiletypeModal,
}) {
    const hideFiletypeDialog = () => {
        setShowFiletypeModal(false);
    };

    const uploadFiles = async () => {
        const filePaths = await ImportService.showUploadFilesDialog();
        hideFiletypeDialog();
        const files = await getElectronFiles(filePaths);
        setElectronFiles(files);
    };

    const uploadDirs = async () => {
        const filePaths = await ImportService.showUploadDirsDialog();
        hideFiletypeDialog();
        const files = await getElectronFiles(filePaths);
        setElectronFiles(files);
    };

    return (
        <Modal
            show={showFiletypeModal}
            aria-labelledby="contained-modal-title-vcenter"
            centered
            dialogClassName="file-type-choice-modal">
            <Modal.Header onHide={hideFiletypeDialog}>
                <Modal.Title
                    id="contained-modal-title-vcenter"
                    style={{
                        fontSize: '1.8em',
                        marginLeft: '5%',
                        color: 'white',
                    }}>
                    <b>{constants.CHOOSE_UPLOAD_TYPE}</b>
                </Modal.Title>
                <IoMdClose
                    size={30}
                    onClick={hideFiletypeDialog}
                    style={{ cursor: 'pointer' }}
                />
            </Modal.Header>
            <Modal.Body
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'space-around',
                    height: '20vh',
                }}>
                <Button
                    variant="light"
                    onClick={uploadFiles}
                    style={{
                        width: '90%',
                    }}>
                    <LeftAlignedDiv>
                        <img src="/images/file-upload.svg"></img>
                        <b>{constants.UPLOAD_FILES}</b>
                    </LeftAlignedDiv>
                    <RightAlignedDiv>
                        <IoIosArrowForward />
                    </RightAlignedDiv>
                </Button>
                <Button
                    variant="light"
                    onClick={uploadDirs}
                    style={{ width: '90%' }}>
                    <LeftAlignedDiv>
                        <img src="/images/folder-upload.svg"></img>
                        <b>{constants.UPLOAD_DIRS}</b>
                    </LeftAlignedDiv>
                    <RightAlignedDiv>
                        <IoIosArrowForward />
                    </RightAlignedDiv>
                </Button>
            </Modal.Body>
        </Modal>
    );
}
