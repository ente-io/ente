import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import { getActualKey } from 'utils/common/key';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import CollectionDropZone from './CollectionDropZone';
import PreviewCard from './PreviewCard';

function CollectionSelector({
    uploadModalView,
    closeUploadModal,
    collectionLatestFile,
    showProgress,
    setData,
    setPercentComplete,
}) {

    const [token, setToken] = useState(null);
    const [encryptionKey, setEncryptionKey] = useState(null);
    useEffect(() => {
        (async () => {
            setToken(getData(LS_KEYS.USER).token);
            setEncryptionKey(await getActualKey());
        })();
    });
    const CollectionIcons = collectionLatestFile?.map((item) => (
        <CollectionDropZone key={item.collectionID}
            closeModal={closeUploadModal}
            collectionLatestFile={item}
            noDragEventsBubbling
            showProgress={showProgress}
            token={token}
            encryptionKey={encryptionKey}
            setData={setData}
            setPercentComplete={setPercentComplete}
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
            show={uploadModalView}
            aria-labelledby='contained-modal-title-vcenter'
            centered
            onHide={closeUploadModal}
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
                <Button onClick={closeUploadModal}>Close</Button>
            </Modal.Footer>
        </Modal>
    );
}

export default CollectionSelector;
