import { Button, DialogActions, DialogContent, Stack } from '@mui/material';
import React from 'react';
import { ExportStats } from 'types/export';
import { formatDateTime } from 'utils/time';
import constants from 'utils/strings/constants';
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
    const totalFiles = props.exportStats.failed + props.exportStats.success;
    return (
        <>
            <DialogContent>
                <Stack spacing={2.5}>
                    <FlexWrapper>
                        <Label width="40%">{constants.LAST_EXPORT_TIME}</Label>
                        <Value width="60%">
                            {formatDateTime(props.lastExportTime)}
                        </Value>
                    </FlexWrapper>
                    <FlexWrapper>
                        <Label width="40%">
                            {constants.SUCCESSFULLY_EXPORTED_FILES}
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
                                {constants.FAILED_EXPORTED_FILES}
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
                        {constants.RETRY_EXPORT_}
                    </Button>
                ) : (
                    <Button
                        size="large"
                        color="primary"
                        onClick={props.exportFiles}>
                        {constants.EXPORT_AGAIN}
                    </Button>
                )}
                <Button color="secondary" size="large" onClick={props.onHide}>
                    {constants.CLOSE}
                </Button>
            </DialogActions>
        </>
    );
}
