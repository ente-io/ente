import React, { useEffect, useRef, useState } from 'react';
import { Modal, Form, Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    createCollectionView;
    setCreateCollectionView;
    autoFilledName;
    uploadFiles;
}
export default function CreateCollection(props: Props) {
    const [albumName, setAlbumName] = useState('');
    const inputRef = useRef<HTMLInputElement>(null);

    const handleChange = (event) => {
        setAlbumName(event.target.value);
    };

    const handleSubmit = async (event) => {
        event.preventDefault();
        props.setCreateCollectionView(false);
        await props.uploadFiles(albumName, null);
    };
    useEffect(() => {
        setAlbumName(props.autoFilledName);
        inputRef.current && inputRef.current.focus();
    }, [props.autoFilledName]);
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
                            ref={inputRef}
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
