import { Button, DialogActions, DialogContent } from '@mui/material';
import React from 'react';
import { t } from 'i18next';

interface Props {
    startExport: () => void;
    totalFileCount: number;
}
export default function ExportInit({ startExport }: Props) {
    return (
        <DialogContent>
            <DialogActions>
                <Button size="large" color="accent" onClick={startExport}>
                    {t('START')}
                </Button>
            </DialogActions>
        </DialogContent>
    );
}
