import CollectionSelector from 'pages/gallery/components/CollectionSelector';
import React, { useRef } from 'react';
import { Button } from 'react-bootstrap';

const UploadButton = ({ modalView, closeModal, showModal, collections }) => {
  return (
    <>
      <Button variant='primary' onClick={showModal}>
        Upload New Photos
      </Button>
      <CollectionSelector
        modalView={modalView}
        closeModal={closeModal}
        showModal={showModal}
        collections={collections}
      />
    </>
  );
};

export default UploadButton;
