import React, { useEffect, useState } from 'react';
import { Button, Form, Modal } from 'react-bootstrap';
import { createAlbum } from 'services/collectionService';
import UploadService from 'services/uploadService';
import { CollectionAndItsLatestFile } from 'services/collectionService';
import { getToken } from 'utils/common/key';
import constants from 'utils/strings/constants';

export default function CreateCollection(props) {
    const {
        acceptedFiles,
        setProgressView,
        progressBarProps,
        refetchData,
        modalView,
        closeModal,
        closeUploadModal,
        setUploadErrors,
        setBannerErrorCode,
    } = props;
    const [albumName, setAlbumName] = useState('');

    const handleChange = (event) => {
        setAlbumName(event.target.value);
    };

    useEffect(() => {
        if (acceptedFiles == null) {
            return;
        }
        let commonPathPrefix: string = (() => {
            const paths: string[] = acceptedFiles.map((files) => files.path);
            paths.sort();
            let firstPath = paths[0],
                lastPath = paths[paths.length - 1],
                L = firstPath.length,
                i = 0;
            while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
            return firstPath.substring(0, i);
        })();
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substr(
                1,
                commonPathPrefix.lastIndexOf('/') - 1
            );
        }
        setAlbumName(commonPathPrefix);
    }, [acceptedFiles]);
    const handleSubmit = async (event) => {
        try {
            const token = getToken();
            event.preventDefault();
            progressBarProps.setPercentComplete(0);
            setProgressView(true);

            closeModal();
            closeUploadModal();

            const collection = await createAlbum(albumName);

            const collectionAndItsLatestFile: CollectionAndItsLatestFile = {
                collection,
                file: null,
            };

            await UploadService.uploadFiles(
                acceptedFiles,
                collectionAndItsLatestFile,
                token,
                progressBarProps,
                setUploadErrors
            );
            refetchData();
        } catch (err) {
            setBannerErrorCode(err.message);
            setProgressView(false);
        }
    };
    return (
        <Modal
            show={modalView}
            onHide={closeModal}
            centered
            backdrop="static"
            style={{ background: 'rgba(0, 0, 0, 0.8)' }}
        >
            <Modal.Header closeButton>
                <Modal.Title>{constants.CREATE_COLLECTION}</Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <Form onSubmit={handleSubmit}>
                    <Form.Group controlId="formBasicEmail">
                        <Form.Control
                            type="text"
                            placeholder={constants.ALBUM_NAME}
                            value={albumName}
                            onChange={handleChange}
                        />
                    </Form.Group>
                    <Button
                        variant="primary"
                        type="submit"
                        style={{ width: '100%' }}
                    >
                        {constants.CREATE}
                    </Button>
                </Form>
            </Modal.Body>
        </Modal>
    );
}
