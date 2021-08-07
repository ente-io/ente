import React from 'react';
import Alert from 'react-bootstrap/Alert';
import { getVariantColor } from './LinkButton';

interface Props{
    bannerMessage?:any
    variant?:string
    children?:any
}
export default function AlertBanner(props:Props) {
    return (
        <Alert
            variant={props.variant??'danger'}
            style={{
                display: props.bannerMessage || props.children ? 'block' : 'none',
                textAlign: 'center',

                border: 'none',
                borderBottom: '1px solid',
                background: 'none',
                borderRadius: '0px',
                color: getVariantColor(props.variant),
                padding: 0,
                margin: '0 25px',
                marginBottom: '10px',
            }}
        >
            {props.bannerMessage?props.bannerMessage:props.children}
        </Alert>
    );
}
