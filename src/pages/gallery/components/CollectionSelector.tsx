import React from 'react';
import { Button, Card, Col, Container, Modal, Row } from 'react-bootstrap';
import FileUpload from './DragAndDropUpload';

function CollectionSelector({ modalView, closeModal, collections }) {
  const CollectionIcons = collections.map((item) => (
    <FileUpload closeModal={closeModal} collection={item} noDragEventsBubbling>
      <Card
        style={{
          margin: '5px',
          padding: '5px',
          width: 'auto',
          height: 'auto',
          position: 'relative',
          border: 'solid',
          overflow: 'auto',
          float: 'left',
          cursor: 'pointer',
        }}
      >
        <Card.Body>{item.name}</Card.Body>{' '}
      </Card>
    </FileUpload>
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
      <Modal.Body>
        <Container>
          <Row>{CollectionIcons}</Row>
        </Container>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={closeModal}>Close</Button>
      </Modal.Footer>
    </Modal>
  );
}

export default CollectionSelector;
