import { Button, DialogActions, DialogContent, Stack } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ExportStats } from 'types/export';
import { formatDateTime } from 'utils/time/format';
import { FlexWrapper, Label, Value } from './Container';
import { ComfySpan } from './ExportInProgress';

interface Props {
    onHide: () => void;
    lastExportTime: number;
    exportStats: ExportStats;
    exportFiles: () => void;
    retryFailed: () => void;
}

export default function ExportFinished(props: Props) {
    const { t } = useTranslation();
    const totalFiles = props.exportStats.failed + props.exportStats.success;
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
                        <Value width="60%">
                            <ComfySpan>
                                {props.exportStats.success} / {totalFiles}
                            </ComfySpan>
                        </Value>
                    </FlexWrapper>
                    {props.exportStats.failed > 0 && (
                        <FlexWrapper>
                            <Label width="40%">
                                {t('FAILED_EXPORTED_FILES')}
                            </Label>
                            <Value width="60%">
                                <ComfySpan>
                                    {props.exportStats.failed} / {totalFiles}
                                </ComfySpan>
                            </Value>
                        </FlexWrapper>
                    )}
                </Stack>
            </DialogContent>
            <DialogActions>
                {props.exportStats.failed !== 0 ? (
                    <Button
                        size="large"
                        color="accent"
                        onClick={props.retryFailed}>
                        {t('RETRY_EXPORT')}
                    </Button>
                ) : (
                    <Button
                        size="large"
                        color="primary"
                        onClick={props.exportFiles}>
                        {t('EXPORT_AGAIN')}
                    </Button>
                )}
                <Button color="secondary" size="large" onClick={props.onHide}>
                    {t('CLOSE')}
                </Button>
            </DialogActions>
        </>
    );
}
