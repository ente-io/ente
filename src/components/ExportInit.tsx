import { Button, DialogActions } from '@mui/material';
import React from 'react';
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
        <DialogActions>
            <Button size="large" color="accent" onClick={props.startExport}>
                {constants.START}
            </Button>
        </DialogActions>
    );
}
