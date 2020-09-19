import React from 'react';
import Card from 'react-bootstrap/Card';
import { fileData } from 'services/fileService';

interface IProps {
    data: fileData,
}

export default function PreviewCard(props: IProps) {
    const { data } = props;

    return (<Card>
        <Card.Body>
            <div>ID: {data?.id}</div>
            <div>MetaData: {JSON.stringify(data?.metadata)}</div>
        </Card.Body>
    </Card>);
}
