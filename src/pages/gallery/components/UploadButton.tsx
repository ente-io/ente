import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';

function UploadButton({ showModal }) {
    return (
        <Button variant="primary" onClick={showModal}>
            {constants.UPLOAD_BUTTON_TEXT}
        </Button>
    );
}

export default UploadButton;
