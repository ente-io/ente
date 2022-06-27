import { Button, DialogActions, DialogContent } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';

interface Props {
    startExport: () => void;
}
export default function ExportInit({ startExport }: Props) {
    return (
        <DialogContent>
            <DialogActions>
                <Button size="large" color="accent" onClick={startExport}>
                    {constants.START}
                </Button>
            </DialogActions>
        </DialogContent>
    );
}
