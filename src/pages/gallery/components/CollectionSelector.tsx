import React from 'react';
import { Button, Card, Col, Container, Modal, Row } from 'react-bootstrap';
import FileUpload from './DragAndDropUpload';

function CollectionSelector({
  modalView,
  closeModal,
  collectionLatestFile,
  showProgress,
}) {
  const CollectionIcons = collectionLatestFile.map((item) => (
    <FileUpload
      closeModal={closeModal}
      collectionLatestFile={item}
      noDragEventsBubbling
      showProgress={showProgress}
    >
      <Card
        style={{
          margin: '5px',
          padding: '5px',
          width: '95%',
          height: '150px',
          position: 'relative',
          border: 'solid',
          float: 'left',
          cursor: 'pointer',
        }}
      >
        <Card.Img
          variant='top'
          src={item.thumb}
          style={{ width: '100%', height: '100%' }}
        />
        <Card.Body
          style={{
            padding: '5px',
          }}
        >
          {item.collectionName}
        </Card.Body>{' '}
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
