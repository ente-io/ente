import { OverlayTrigger, Tooltip } from 'react-bootstrap';
import React from 'react';

interface IconWithMessageProps {
    children?: any;
    message: string;
}

export const IconWithMessage = (props: IconWithMessageProps) => (
    <OverlayTrigger
        placement="bottom"
        overlay={
            <Tooltip id="on-hover-info" style={{ zIndex: 1002 }}>
                {props.message}
            </Tooltip>
        }>
        {props.children}
    </OverlayTrigger>
);
