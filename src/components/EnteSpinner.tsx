import React from 'react';
import { Spinner } from 'react-bootstrap';

export default function EnteSpinner(props) {
    return (
        <Spinner
            {...props}
            animation="border"
            style={{
                width: '36px',
                height: '36px',
                borderWidth: '0.20em',
                color: '#51cd7c',
            }}
            role="status"
        />
    );
}
