import { DeadCenter } from 'pages/gallery';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    show: boolean;
    onHide: () => void;
    updateExportFolder: (newFolder: string) => void;
    exportFolder: string;
    startExport: () => void;
    exportSize: string;
    selectExportDirectory: () => void;
}
export default function ExportInit(props: Props) {
    return (
        <>
            <DeadCenter>
                <Button
                    variant="outline-success"
                    size="lg"
                    style={{
                        padding: '6px 3em',
                        margin: '0 20px',
                        marginBottom: '20px',
                        flex: 1,
                        whiteSpace: 'nowrap',
                    }}
                    onClick={props.startExport}>
                    {constants.START}
                </Button>
            </DeadCenter>
        </>
    );
}
