import CollectionSelector from 'pages/gallery/components/CollectionSelector';
import React, { useRef } from 'react';
import { Button } from 'react-bootstrap';
import Dropzone from 'react-dropzone';

const UploadButton = ({ modalView, closeModal, showModal }) => {
  return (
    <>
      <Button variant='primary' onClick={showModal}>
        Upload New Photos
      </Button>
      <CollectionSelector
        modalView={modalView}
        closeModal={closeModal}
        showModal={showModal}
      />
    </>
  );
};

export default UploadButton;
