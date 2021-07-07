import { DeadCenter } from 'pages/gallery';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { Row, Label, Value } from './Container';
import FolderIcon from './icons/FolderIcon';
import exportService from 'services/exportService';
import { ExportState } from './ExportModal';

interface Props {
    show: boolean
    onHide: () => void
    updateExportFolder: (newFolder: string) => void;
    updateExportState: (newState: ExportState) => void;
    exportFolder: string
    exportFiles: () => void
    exportSize: string;
}
export default function ExportInit(props: Props) {
    const selectNewDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        newFolder && props.updateExportFolder(newFolder);
    };

    const startExport = async () => {
        if (!props.exportFolder) {
            await selectNewDirectory();
        }
        props.exportFiles();
        props.updateExportState(ExportState.INPROGRESS);
    };
    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            attributes={{
                title: constants.EXPORT_DATA,
            }}
        >
            <div style={{ borderBottom: '1px solid #444', marginBottom: '20px', padding: '0 5%' }}>
                <Row>
                    <Label width="40%">{constants.DESTINATION}</Label>
                    <Value width="60%">
                        {!props.exportFolder ?
                            (<Button variant={'outline-success'} onClick={selectNewDirectory}>{constants.SELECT_FOLDER}</Button>) :
                            (<>
                                <span style={{ overflow: 'hidden', direction: 'rtl', height: '1.5rem', width: '90%', whiteSpace: 'nowrap' }}>
                                    {props.exportFolder}
                                </span>
                                <div onClick={selectNewDirectory} style={{ width: '10%', marginLeft: '5px', cursor: 'pointer' }}>
                                    <FolderIcon />
                                </div>
                            </>)
                        }
                    </Value>
                </Row>
                <Row>
                    <Label width="40%">{constants.TOTAL_EXPORT_SIZE} </Label><Value width="60%">{props.exportSize} GB</Value>
                </Row>
            </div>
            <DeadCenter >
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
                    onClick={startExport}
                >{constants.START}</Button>
            </DeadCenter>
        </MessageDialog >
    );
}
