import {
    Button,
    DialogActions,
    DialogContent,
    Stack,
    Typography,
} from '@mui/material';
import { t } from 'i18next';
import { formatDateTime } from '@ente/shared/time/format';
import { SpaceBetweenFlex } from '@ente/shared/components/Container';
import { formatNumber } from 'utils/number/format';
import ExportPendingList from './ExportPendingList';
import { useState } from 'react';
import LinkButton from './pages/gallery/LinkButton';
import { EnteFile } from 'types/file';

interface Props {
    pendingExports: EnteFile[];
    collectionNameMap: Map<number, string>;
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
                        {props.pendingExports.length ? (
                            <LinkButton onClick={openPendingFileList}>
                                {formatNumber(props.pendingExports.length)}
                            </LinkButton>
                        ) : (
                            <Typography>
                                {formatNumber(props.pendingExports.length)}
                            </Typography>
                        )}
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
                pendingExports={props.pendingExports}
                collectionNameMap={props.collectionNameMap}
                isOpen={pendingFileListView}
                onClose={closePendingFileList}
            />
        </>
    );
}
