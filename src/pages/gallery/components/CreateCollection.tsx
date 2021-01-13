import React, { useState } from 'react';
import { Modal } from 'react-bootstrap';
import { createAlbum } from 'services/collectionService';
import UploadService from 'services/uploadService';
import { collectionLatestFile, fetchData } from 'services/fileService'

export default function CreateCollection(props) {

    const { masterKey, token, closeModal, acceptedFiles, setData, setProgressView, progressBarProps } = props;
    const [albumName, setAlbumName] = useState("");

    const handleChange = (event) => { setAlbumName(event.target.value); }

    const handleSubmit = async (event) => {
        event.preventDefault();
        closeModal();

        const collection = await createAlbum(albumName, masterKey, token);

        const collectionLatestFile: collectionLatestFile = { collection, file: null }
        progressBarProps.setPercentComplete(0);
        setProgressView(true);

        await UploadService.uploadFiles(acceptedFiles, collectionLatestFile, token, progressBarProps);
        setData(await fetchData(token, [collectionLatestFile.collection]));
        setProgressView(false);
    }
    return (
        <Modal
            {...props}
            size='lg'
            aria-labelledby='contained-modal-title-vcenter'
            centered
            backdrop="static"
        >
            <Modal.Header>
                <Modal.Title id='contained-modal-title-vcenter'>
                    Create Collection
        </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <form onSubmit={handleSubmit}>
                    <label>
                        Album Name:
                    <input type="text" value={albumName} onChange={handleChange} />
                    </label>
                    <input type="submit" value="Submit" />
                </form>
            </Modal.Body>
        </Modal>
    );
}