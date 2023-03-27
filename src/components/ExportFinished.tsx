import {
    Button,
    DialogActions,
    DialogContent,
    Stack,
    Typography,
} from '@mui/material';
import React from 'react';
import { t } from 'i18next';
import { formatDateTime } from 'utils/time/format';
import { SpaceBetweenFlex } from './Container';

interface Props {
    pendingFileCount: number;
    onHide: () => void;
    lastExportTime: number;
    startExport: () => void;
}

export default function ExportFinished(props: Props) {
    return (
        <>
            <DialogContent>
                <Stack pr={2}>
                    <SpaceBetweenFlex minHeight={'48px'}>
                        <Typography color={'text.secondary'}>
                            {t('PENDING_ITEMS')}
                        </Typography>
                        <Typography>{props.pendingFileCount}</Typography>
                    </SpaceBetweenFlex>
                    <SpaceBetweenFlex minHeight={'48px'}>
                        <Typography color="text.secondary">
                            {t('LAST_EXPORT_TIME')}
                        </Typography>
                        <Typography>
                            {formatDateTime(props.lastExportTime)}
                        </Typography>
                    </SpaceBetweenFlex>
                </Stack>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" size="large" onClick={props.onHide}>
                    {t('CLOSE')}
                </Button>
                <Button
                    size="large"
                    color="primary"
                    onClick={props.startExport}>
                    {t('EXPORT_AGAIN')}
                </Button>
            </DialogActions>
        </>
    );
}
