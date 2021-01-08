import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import CollectionDropZone from './CollectionDropZone';
import PreviewCard from './PreviewCard';

function CollectionSelector({
    modalView,
    closeModal,
    collectionLatestFile,
    showProgress,
}) {

    const [token, setToken] = useState(null);
    useEffect(() => {
        setToken(getData(LS_KEYS.USER).token);
    });
    const CollectionIcons = collectionLatestFile?.map((item) => (
        <CollectionDropZone key={item.collectionID}
            closeModal={closeModal}
            collectionLatestFile={item}
            noDragEventsBubbling
            showProgress={showProgress}
            token={token}
        >
            <Card style={{ cursor: 'pointer', border: 'solid', width: "95%", marginBottom: "5px", padding: "auto" }}>
                <PreviewCard data={item.file} updateUrl={() => { }} onClick={() => { }} />
                <Card.Body>
                    <Card.Text>{item.collection.name}</Card.Text>
                </Card.Body>
            </Card>
        </CollectionDropZone>
    ));
    return (
        <Modal
            show={modalView}
            aria-labelledby='contained-modal-title-vcenter'
            centered
            onHide={closeModal}
        >
            <Modal.Header closeButton>
                <Modal.Title id='contained-modal-title-vcenter'>
                    Select/Click on Collection to upload
        </Modal.Title>
            </Modal.Header>
            <Modal.Body style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap" }}>
                {CollectionIcons}
            </Modal.Body>
            <Modal.Footer>
                <Button onClick={closeModal}>Close</Button>
            </Modal.Footer>
        </Modal>
    );
}

export default CollectionSelector;
