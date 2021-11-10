import React from 'react';
import { Spinner } from 'react-bootstrap';

export default function EnteSpinner(props) {
    const { style, ...others } = props ?? {};
    return (
        <Spinner
            animation="border"
            style={{
                width: '36px',
                height: '36px',
                borderWidth: '0.20em',
                color: '#51cd7c',
                ...(style && style),
            }}
            {...others}
            role="status"
        />
    );
}
