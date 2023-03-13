import { Button, DialogActions, DialogContent } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';

interface Props {
    startExport: () => void;
}
export default function ExportInit({ startExport }: Props) {
    const { t } = useTranslation();

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
