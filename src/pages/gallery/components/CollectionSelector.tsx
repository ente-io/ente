import React from 'react';
import { Button, Card, Col, Container, Modal, Row } from 'react-bootstrap';

function CollectionSelector({ modalView, closeModal, showModal, collections }) {
  
  const CollectionIcons = [1,2,3,4].map((item) => (
    <Card style={{ width: '30%' }}>
      <Card.Body>Blah Blah</Card.Body>{' '}
    </Card>
  ));
  console.log(CollectionIcons);
  return (
    <Modal
      show={modalView}
      aria-labelledby='contained-modal-title-vcenter'
      centered
      onHide={closeModal}
    >
      <Modal.Header closeButton>
        <Modal.Title id='contained-modal-title-vcenter'>
          Modal heading
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
