import { OverlayTrigger } from 'react-bootstrap';
import React from 'react';

interface IconWithMessageProps {
    children?: any;
    message: string;
}

export const IconWithMessage = (props: IconWithMessageProps) => (
    <OverlayTrigger
        placement="bottom"
        overlay={<p style={{ zIndex: 1002 }}>{props.message}</p>}>
        {props.children}
    </OverlayTrigger>
);
