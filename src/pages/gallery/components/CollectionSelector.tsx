import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import { getActualKey } from 'utils/common/key';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import CollectionDropZone from './CollectionDropZone';
import PreviewCard from './PreviewCard';

function CollectionSelector({
    uploadModalView,
    closeUploadModal,
    showUploadModal,
    collectionLatestFile,
    setProgressView,
    setData,
    progressBarProps,
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
            showModal={showUploadModal}
            collectionLatestFile={item}
            noDragEventsBubbling
            setProgressView={setProgressView}
            token={token}
            encryptionKey={encryptionKey}
            setData={setData}
            progressBarProps={progressBarProps}
        >
            <Card>
                <PreviewCard data={item.file} updateUrl={() => { }} onClick={() => { }} />
                <Card.Text style={{ textAlign: 'center' }}>{item.collection.name}</Card.Text>
            </Card>

        </CollectionDropZone>
    ));
    return (
        <Modal
            show={uploadModalView}
            onHide={closeUploadModal}
            dialogClassName="modal-90w"
        >
            <Modal.Header closeButton>
                <Modal.Title >
                    Select/Click on Collection to upload
                    </Modal.Title>
            </Modal.Header>
            <Modal.Body style={{ display: "flex", justifyContent: "space-around", flexWrap: "wrap" }}>
                {CollectionIcons}
            </Modal.Body>
            <Modal.Footer>
                <Button onClick={closeUploadModal}>Close</Button>
            </Modal.Footer>
        </Modal>
    );
}

export default CollectionSelector;
