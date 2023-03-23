import {
    Button,
    DialogActions,
    DialogContent,
    Stack,
    Typography,
} from '@mui/material';
import React from 'react';
import { t } from 'i18next';
import { ExportStats } from 'types/export';
import { formatDateTime } from 'utils/time/format';
import { SpaceBetweenFlex } from './Container';

interface Props {
    onHide: () => void;
    lastExportTime: number;
    exportStats: ExportStats;
    startExport: () => void;
}

export default function ExportFinished(props: Props) {
    return (
        <>
            <DialogContent>
                <Stack spacing={2.5} pr={2}>
                    <SpaceBetweenFlex>
                        <Typography color="text.secondary">
                            {t('LAST_EXPORT_TIME')}
                        </Typography>
                        <Typography>
                            {formatDateTime(props.lastExportTime)}
                        </Typography>
                    </SpaceBetweenFlex>
                    <SpaceBetweenFlex>
                        <Typography color="text.secondary">
                            {t('SUCCESSFULLY_EXPORTED_FILES')}
                        </Typography>
                        <Typography>{props.exportStats.success}</Typography>
                    </SpaceBetweenFlex>
                    {props.exportStats.failed > 0 && (
                        <SpaceBetweenFlex>
                            <Typography color="text.secondary">
                                {t('FAILED_EXPORTED_FILES')}
                            </Typography>
                            <Typography>{props.exportStats.failed}</Typography>
                        </SpaceBetweenFlex>
                    )}
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
