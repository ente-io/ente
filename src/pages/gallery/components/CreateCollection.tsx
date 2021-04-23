import React, { useEffect, useRef, useState } from 'react';
import { Modal, Form, Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { UPLOAD_STRATEGY } from './Upload';

interface Props {
    createCollectionView;
    setCreateCollectionView;
    autoFilledName;
    uploadFiles: (strategy: UPLOAD_STRATEGY, collectionName) => void;
    triggerFocus;
}
export default function CreateCollection(props: Props) {
    const [albumName, setAlbumName] = useState('');
    const handleChange = (event) => {
        setAlbumName(event.target.value);
    };
    const collectionNameInputRef = useRef(null);
    const handleSubmit = async (event) => {
        event.preventDefault();
        props.setCreateCollectionView(false);
        await props.uploadFiles(UPLOAD_STRATEGY.SINGLE_COLLECTION, albumName);
    };
    useEffect(() => {
        setAlbumName(props.autoFilledName);
    }, [props.autoFilledName]);

    useEffect(() => {
        setTimeout(() => {
            collectionNameInputRef.current?.focus();
        }, 200);
    }, [props.triggerFocus]);
    return (
        <Modal
            show={props.createCollectionView}
            onHide={() => props.setCreateCollectionView(false)}
            centered
            backdrop="static"
            style={{ background: 'rgba(0, 0, 0, 0.8)' }}
            dialogClassName="ente-modal"
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
                            ref={collectionNameInputRef}
                        />
                    </Form.Group>
                    <Button
                        variant="outline-success"
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
