import React, { useEffect, useState } from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import CollectionDropZone from './CollectionDropZone';
import AddCollection from './AddCollection';
import PreviewCard from './PreviewCard';
import constants from 'utils/strings/constants';

function CollectionSelector(props) {
    const {
        uploadModalView,
        closeUploadModal,
        showUploadModal,
        collectionLatestFile,
        ...rest
    } = props;


    const CollectionIcons = collectionLatestFile?.map((item) => (
        <CollectionDropZone key={item.collection.id}
            {...rest}
            closeModal={closeUploadModal}
            showModal={showUploadModal}
            collectionLatestFile={item}
        >
            <Card>
                <PreviewCard data={item.file} updateUrl={() => { }} forcedEnable />
                <Card.Text className="text-center">{item.collection.name}</Card.Text>
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
                    {constants.SELECT_COLLECTION}
                </Modal.Title>
            </Modal.Header>
            <Modal.Body style={{ display: "flex", justifyContent: "flex-start", flexWrap: "wrap" }}>
                <AddCollection
                    {...rest}
                    showUploadModal={showUploadModal}
                    closeUploadModal={closeUploadModal}
                />
                {CollectionIcons}
            </Modal.Body>
        </Modal>
    );
}

export default CollectionSelector;
