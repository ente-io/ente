import React from 'react';
import { Button } from 'react-bootstrap';

function UploadButton({ showModal }) {
    return (
        <Button variant='primary' onClick={showModal}>
            Upload New Photos
        </Button>
    );
};

export default UploadButton;
