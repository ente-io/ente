import React from 'react';
import { Card } from 'react-bootstrap';

type Size = 'sm' | 'md' | 'lg';

const EnteCard = ({
    size,
    children,
    style,
}: {
    size: Size;
    children?: any;
    style?: any;
}) => {
    let minWidth: string;
    let padding: string;
    switch (size) {
        case 'sm':
            minWidth = '320px';
            padding = '0px';
            break;
        case 'md':
            minWidth = '460px';
            padding = '10px';
            break;

        default:
            minWidth = '480px';
            padding = '10px';
            break;
    }
    return (
        <Card style={{ minWidth, padding, ...style }} className="text-center">
            {children}
        </Card>
    );
};

export default EnteCard;
