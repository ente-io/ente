import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import CollectionDropZone from './CollectionDropZone';
import AddCollection from './AddCollection';
import PreviewCard from './PreviewCard';

function CollectionSelector(props) {
    const {
        uploadModalView,
        closeUploadModal,
        collectionLatestFile,
        ...rest
    } = props;


    const CollectionIcons = collectionLatestFile?.map((item) => (
        <CollectionDropZone
            {...rest}
            closeModal={closeUploadModal}
            collectionLatestFile={item}
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
                <AddCollection
                    {...rest}
                    closeUploadModal={closeUploadModal}
                />
                {CollectionIcons}
            </Modal.Body>
            <Modal.Footer>
                <Button onClick={closeUploadModal}>Close</Button>
            </Modal.Footer>
        </Modal>
    );
}

export default CollectionSelector;
