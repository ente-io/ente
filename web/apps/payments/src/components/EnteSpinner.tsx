import React from 'react';
import { Spinner } from 'react-bootstrap';

export default function EnteSpinner(props: any) {
    return (
        <Spinner {...props} animation="border" variant="success" role="status">
            <span className="sr-only">Loading...</span>
        </Spinner>
    );
}
