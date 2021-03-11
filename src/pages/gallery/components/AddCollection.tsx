import React, { useEffect, useState } from 'react';
import { Button, Card, Form, Modal } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import { CollectionIcon } from './CollectionSelector';

const ImageContainer = styled.div`
    min-height: 192px;
    max-width: 192px;
    border: 1px solid #555;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
`;

export default function AddCollection({ uploadFiles, autoFilledName }) {
    const [createCollectionView, setCreateCollectionView] = useState(false);

    const [albumName, setAlbumName] = useState('');

    const handleChange = (event) => {
        setAlbumName(event.target.value);
    };
    useEffect(() => setAlbumName(autoFilledName), []);

    const handleSubmit = async (event) => {
        event.preventDefault();
        await uploadFiles(null, albumName);
    };
    return (
        <>
            <CollectionIcon
                style={{ margin: '10px' }}
                onClick={() => setCreateCollectionView(true)}
            >
                <Card>
                    <ImageContainer>+</ImageContainer>
                    <Card.Text style={{ textAlign: 'center' }}>
                        {constants.CREATE_COLLECTION}
                    </Card.Text>
                </Card>
            </CollectionIcon>
            <Modal
                show={createCollectionView}
                onHide={() => setCreateCollectionView(false)}
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
        </>
    );
}
