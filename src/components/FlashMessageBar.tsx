import { FlashMessage } from 'pages/_app';
import React from 'react';
import Alert from 'react-bootstrap/Alert';


export default function FlashMessageBar({ flashMessage, onClose }: { flashMessage: FlashMessage, onClose: () => void }) {
    return (
        <Alert
            className="flash-message text-center"
            variant={flashMessage.severity}
            dismissible
            onClose={onClose}
        >
            <div style={{ maxWidth: '1024px', width: '80%', margin: 'auto' }}>
                {flashMessage.message}
            </div>
        </Alert>
    );
}
