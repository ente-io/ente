import React from 'react';
import { Button } from 'react-bootstrap';
import Dropzone from 'react-dropzone';

const UploadButton = () => {
  return (
    <Dropzone
      onDrop={(acceptedFiles) => {
        console.log(acceptedFiles);
      }}
    >
      {({ getRootProps, getInputProps }) => (
        <div {...getRootProps()}>
          <input {...getInputProps()} />
          <Button>Upload</Button>
        </div>
      )}
    </Dropzone>
  );
};

export default UploadButton;
