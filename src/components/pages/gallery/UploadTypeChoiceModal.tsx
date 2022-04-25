import { Modal, Button, Container, Row } from 'react-bootstrap';
import React from 'react';
import constants from 'utils/strings/constants';
import { IoIosArrowForward, IoMdClose } from 'react-icons/io';
import FileUploadIcon from 'components/icons/FileUploadIcon';
import FolderUploadIcon from 'components/icons/FolderUploadIcon';
import { BsGoogle } from 'react-icons/bs';

function UploadTypeRow({ uploadFunc, Icon, uploadName }) {
    return (
        <Row className="justify-content-sm-center py-2">
            <Button
                variant="light"
                onClick={uploadFunc}
                style={{ width: '90%', height: '50px' }}>
                <Container>
                    <Row>
                        <div>
                            <Icon />
                            <b className="ml-2">{uploadName}</b>
                        </div>
                        <div className="ml-auto d-flex align-items-center">
                            <IoIosArrowForward />
                        </div>
                    </Row>
                </Container>
            </Button>
        </Row>
    );
}

function GoogleIcon() {
    return (
        <BsGoogle
            size={25}
            style={{
                marginRight: '0.2em',
                marginLeft: '0.2em',
            }}
        />
    );
}

export default function UploadTypeChoiceModal({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
}) {
    return (
        <Modal
            show={show}
            aria-labelledby="contained-modal-title-vcenter"
            centered
            dialogClassName="file-type-choice-modal">
            <Modal.Header
                onHide={onHide}
                style={{
                    borderBottom: 'none',
                    height: '4em',
                }}>
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
                    onClick={onHide}
                    style={{ cursor: 'pointer' }}
                />
            </Modal.Header>
            <Modal.Body>
                <Container>
                    <UploadTypeRow
                        uploadFunc={uploadFiles}
                        Icon={FileUploadIcon}
                        uploadName={constants.UPLOAD_FILES}
                    />
                    <UploadTypeRow
                        uploadFunc={uploadFolders}
                        Icon={FolderUploadIcon}
                        uploadName={constants.UPLOAD_DIRS}
                    />
                    <UploadTypeRow
                        uploadFunc={uploadGoogleTakeoutZips}
                        Icon={GoogleIcon}
                        uploadName={constants.UPLOAD_GOOGLE_TAKEOUT}
                    />
                </Container>
            </Modal.Body>
        </Modal>
    );
}
