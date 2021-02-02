import React, { useEffect, useState } from 'react';
import { Button, Form, Modal } from 'react-bootstrap';
import { createAlbum } from 'services/collectionService';
import UploadService from 'services/uploadService';
import { collectionLatestFile } from 'services/collectionService'
import { getToken } from 'utils/common/key';

export default function CreateCollection(props) {

    const { acceptedFiles, setProgressView, progressBarProps, refetchData, modalView, closeModal, closeUploadModal, setErrorCode } = props;
    const [albumName, setAlbumName] = useState("");

    const handleChange = (event) => { setAlbumName(event.target.value); }

    useEffect(() => {
        if (acceptedFiles == null)
            return;
        let commonPathPrefix: string = (() => {
            const A: string[] = acceptedFiles.map(files => files.path);

            let a1 = A[0], a2 = A[A.length - 1], L = a1.length, i = 0;
            while (i < L && a1.charAt(i) === a2.charAt(i)) i++;
            return a1.substring(0, i);
        })();
        if (commonPathPrefix)
            commonPathPrefix = commonPathPrefix.substr(1, commonPathPrefix.lastIndexOf('/') - 1);
        setAlbumName(commonPathPrefix);
    }, [acceptedFiles]);
    const handleSubmit = async (event) => {
        try {
            const token = getToken();
            event.preventDefault();

            closeModal();
            closeUploadModal();

            const collection = await createAlbum(albumName);

            const collectionLatestFile: collectionLatestFile = { collection, file: null }

            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
            refetchData();

        }
        catch (err) {
            if (err.response)
                setErrorCode(err.response.status);
        }
        finally {
            setProgressView(false);
        }
    }
    return (
        <Modal
            show={modalView}
            onHide={closeModal}
            centered
            backdrop="static"
        >
            <Modal.Header closeButton>
                <Modal.Title>
                    Create Collection
        </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <Form onSubmit={handleSubmit}>
                    <Form.Group controlId="formBasicEmail">
                        <Form.Label>Album Name:</Form.Label>
                        <Form.Control type="text" placeholder="Enter Album Name" value={albumName} onChange={handleChange} />
                    </Form.Group>
                    <Button variant="primary" type="submit" style={{ width: "100%" }}>
                        Submit
                     </Button>
                </Form>
            </Modal.Body>
        </Modal>
    );
}