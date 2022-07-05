import React from 'react';
import { ExportProgress } from 'types/export';
import {
    Box,
    Button,
    DialogActions,
    DialogContent,
    styled,
} from '@mui/material';
import constants from 'utils/strings/constants';
import { ExportStage } from 'constants/export';
import VerticallyCentered, { FlexWrapper } from './Container';
import { ProgressBar } from 'react-bootstrap';

export const ComfySpan = styled('span')`
    word-spacing: 1rem;
    color: #ddd;
`;

interface Props {
    exportStage: ExportStage;
    exportProgress: ExportProgress;
    resumeExport: () => void;
    cancelExport: () => void;
    pauseExport: () => void;
}

export default function ExportInProgress(props: Props) {
    return (
        <>
            <DialogContent>
                <VerticallyCentered>
                    <Box mb={1.5}>
                        <ComfySpan>
                            {' '}
                            {props.exportProgress.current} /{' '}
                            {props.exportProgress.total}{' '}
                        </ComfySpan>{' '}
                        <span>
                            {' '}
                            files exported{' '}
                            {props.exportStage === ExportStage.PAUSED &&
                                `(paused)`}
                        </span>
                    </Box>
                    <FlexWrapper px={1}>
                        <ProgressBar
                            style={{ width: '100%' }}
                            now={Math.round(
                                (props.exportProgress.current * 100) /
                                    props.exportProgress.total
                            )}
                            animated={
                                !(props.exportStage === ExportStage.PAUSED)
                            }
                            variant="upload-progress-bar"
                        />
                    </FlexWrapper>
                </VerticallyCentered>
            </DialogContent>
            <DialogActions>
                {props.exportStage === ExportStage.PAUSED ? (
                    <Button
                        size="large"
                        onClick={props.resumeExport}
                        color="accent">
                        {constants.RESUME}
                    </Button>
                ) : (
                    <Button
                        size="large"
                        onClick={props.pauseExport}
                        color="primary">
                        {constants.PAUSE}
                    </Button>
                )}
                <Button
                    size="large"
                    onClick={props.cancelExport}
                    color="secondary">
                    {constants.CANCEL}
                </Button>
            </DialogActions>
        </>
    );
}
