import Container from 'components/Container';
import React from 'react';
import { Alert, Button, Modal, ProgressBar } from 'react-bootstrap';

export function UploadProgress(props) {
  const now = 100;
  return (
    <Modal
      {...props}
      size='lg'
      aria-labelledby='contained-modal-title-vcenter'
      centered
    >
      <Modal.Header closeButton>
        <Modal.Title id='contained-modal-title-vcenter'>
          Uploading Files
        </Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <Container>
          {now == 100 ? (
            <Alert variant='success'>Upload Completed</Alert>
          ) : (
            <ProgressBar animated now={now} label={`${now}%`} />
          )}
        </Container>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={props.onHide}>Minimize</Button>
      </Modal.Footer>
    </Modal>
  );
}
