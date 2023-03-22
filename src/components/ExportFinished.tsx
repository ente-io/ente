import { Button, DialogActions, DialogContent, Stack } from '@mui/material';
import React from 'react';
import { t } from 'i18next';
import { ExportStats } from 'types/export';
import { formatDateTime } from 'utils/time/format';
import { FlexWrapper, Label, Value } from './Container';
import { ComfySpan } from './ExportInProgress';

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
                <Stack spacing={2.5}>
                    <FlexWrapper>
                        <Label width="40%">{t('LAST_EXPORT_TIME')}</Label>
                        <Value width="60%">
                            {formatDateTime(props.lastExportTime)}
                        </Value>
                    </FlexWrapper>
                    <FlexWrapper>
                        <Label width="40%">
                            {t('SUCCESSFULLY_EXPORTED_FILES')}
                        </Label>
                        <Value width="60%">{props.exportStats.success}</Value>
                    </FlexWrapper>
                    {props.exportStats.failed > 0 && (
                        <FlexWrapper>
                            <Label width="40%">
                                {t('FAILED_EXPORTED_FILES')}
                            </Label>
                            <Value width="60%">
                                <ComfySpan>
                                    {props.exportStats.failed}
                                </ComfySpan>
                            </Value>
                        </FlexWrapper>
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
