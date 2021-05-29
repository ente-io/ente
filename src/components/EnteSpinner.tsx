import React from 'react';
import {Spinner} from 'react-bootstrap';

export default function EnteSpinner(props) {
    return (
        <Spinner
            {...props}
            animation="border"
            variant="success"
            role="status"
        />
    );
}
