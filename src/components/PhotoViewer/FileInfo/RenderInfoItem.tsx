import React from 'react';
import { Label, Row, Value } from 'components/Container';

export const RenderInfoItem = (label: string, value: string | JSX.Element) => (
    <Row>
        <Label width="30%">{label}</Label>
        <Value width="70%">{value}</Value>
    </Row>
);
