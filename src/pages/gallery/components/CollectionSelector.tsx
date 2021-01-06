import React from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import CollectionDropZone from './CollectionDropZone';

function CollectionSelector({
  modalView,
  closeModal,
  collectionLatestFile,
  showProgress,
}) {
  const CollectionIcons = collectionLatestFile.map((item) => (
    <CollectionDropZone key={item.collectionID}
      closeModal={closeModal}
      collectionLatestFile={item}
      noDragEventsBubbling
      showProgress={showProgress}
    >
      <Card style={{ maxHeight: "20%", cursor: 'pointer', border: 'solid', flexWrap: "nowrap" }}>
        <Card.Img variant="top" src={item.thumb} />
        <Card.Body>
          <Card.Text>{item.collectionName}</Card.Text>
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
