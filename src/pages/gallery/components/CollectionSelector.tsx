import React from 'react';
import { Button, Modal } from 'react-bootstrap';

function CollectionSelector({ modalView, closeModal, showModal }) {
  return (
    <>
      {/* <Button variant='primary' onClick={showModal}>
        Launch demo modal
      </Button> */}

      <Modal show={modalView} onHide={closeModal}>
        <Modal.Header closeButton>
          <Modal.Title>Modal heading</Modal.Title>
        </Modal.Header>
        <Modal.Body>Woohoo, you're reading this text in a modal!</Modal.Body>
        <Modal.Footer>
          <Button variant='secondary' onClick={closeModal}>
            Close
          </Button>
          <Button variant='primary' onClick={closeModal}>
            Save Changes
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
}

export default CollectionSelector;
