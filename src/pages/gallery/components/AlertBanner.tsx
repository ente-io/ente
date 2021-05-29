import React from 'react';
import Alert from 'react-bootstrap/Alert';

export default function AlertBanner({bannerMessage}) {
    return (
        <Alert
            variant="danger"
            style={{
                display: bannerMessage ? 'block' : 'none',
                textAlign: 'center',
            }}
        >
            {bannerMessage}
        </Alert>
    );
}
