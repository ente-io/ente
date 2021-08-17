import React from 'react';
import Alert from 'react-bootstrap/Alert';
import { getVariantColor } from './LinkButton';

interface Props {
    bannerMessage?: any;
    variant?: string;
    children?: any;
    style?: any;
}
export default function AlertBanner(props: Props) {
    return (
        <Alert
            variant={props.variant ?? 'danger'}
            style={{
                display:
                    props.bannerMessage || props.children ? 'block' : 'none',
                textAlign: 'center',
                border: 'none',
                background: 'none',
                borderRadius: '0px',
                color: getVariantColor(props.variant),
                padding: 0,
                margin: 0,
                ...props.style,
            }}>
            {props.bannerMessage ? props.bannerMessage : props.children}
        </Alert>
    );
}
