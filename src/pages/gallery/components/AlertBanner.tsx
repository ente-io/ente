import { BannerMessage } from 'pages/_app';
import React, { useState } from 'react';
import { Alert, Fade } from 'react-bootstrap';

interface Props {
    bannerMessage: BannerMessage;
    setBannerMessage;
}
export default function AlertBanner(props: Props) {
    return (
        <Alert
            variant={props.bannerMessage?.variant}
            style={{
                textAlign: 'center',
            }}
            onClose={() => props.setBannerMessage(null)}
            dismissible
            show={props.bannerMessage != null}
        >
            {props.bannerMessage?.message}
        </Alert>
    );
}
