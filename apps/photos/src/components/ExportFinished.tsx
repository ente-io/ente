import {
    Button,
    DialogActions,
    DialogContent,
    Stack,
    Typography,
} from '@mui/material';
import { t } from 'i18next';
import { formatDateTime } from 'utils/time/format';
import { SpaceBetweenFlex } from './Container';
import { formatNumber } from 'utils/number/format';
import ExportPendingList from './ExportPendingList';
import { useState } from 'react';
import LinkButton from './pages/gallery/LinkButton';

interface Props {
    pendingFileCount: number;
    onHide: () => void;
    lastExportTime: number;
    startExport: () => void;
}

export default function ExportFinished(props: Props) {
    const [pendingFileListView, setPendingFileListView] =
        useState<boolean>(false);

    const openPendingFileList = () => {
        setPendingFileListView(true);
    };

    const closePendingFileList = () => {
        setPendingFileListView(false);
    };
    return (
        <>
            <DialogContent>
                <Stack pr={2}>
                    <SpaceBetweenFlex minHeight={'48px'}>
                        <Typography color={'text.muted'}>
                            {t('PENDING_ITEMS')}
                        </Typography>
                        <LinkButton onClick={openPendingFileList}>
                            {formatNumber(props.pendingFileCount)}
                        </LinkButton>
                    </SpaceBetweenFlex>
                    <SpaceBetweenFlex minHeight={'48px'}>
                        <Typography color="text.muted">
                            {t('LAST_EXPORT_TIME')}
                        </Typography>
                        <Typography>
                            {props.lastExportTime
                                ? formatDateTime(props.lastExportTime)
                                : t('NEVER')}
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
            <ExportPendingList
                isOpen={pendingFileListView}
                onClose={closePendingFileList}
            />
        </>
    );
}
