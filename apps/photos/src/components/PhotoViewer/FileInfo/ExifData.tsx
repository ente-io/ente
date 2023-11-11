import React from 'react';

import { Stack, styled, Typography } from '@mui/material';
import { FileInfoSidebar } from '.';
import Titlebar from 'components/Titlebar';
import { Box } from '@mui/system';
import CopyButton from '@ente/shared/components/CodeBlock/CopyButton';
import { formatDateTimeFull } from '@ente/shared/time/format';
import { t } from 'i18next';

const ExifItem = styled(Box)`
    padding-left: 8px;
    padding-right: 8px;
    display: flex;
    flex-direction: column;
    gap: 4px;
`;

function parseExifValue(value: any) {
    switch (typeof value) {
        case 'string':
        case 'number':
            return value;
        default:
            if (value instanceof Date) {
                return formatDateTimeFull(value);
            }
            try {
                return JSON.stringify(Array.from(value));
            } catch (e) {
                return null;
            }
    }
}
export function ExifData(props: {
    exif: any;
    open: boolean;
    onClose: () => void;
    filename: string;
    onInfoClose: () => void;
}) {
    const { exif, open, onClose, filename, onInfoClose } = props;

    if (!exif) {
        return <></>;
    }
    const handleRootClose = () => {
        onClose();
        onInfoClose();
    };

    return (
        <FileInfoSidebar open={open} onClose={onClose}>
            <Titlebar
                onClose={onClose}
                title={t('EXIF')}
                caption={filename}
                onRootClose={handleRootClose}
                actionButton={
                    <CopyButton
                        code={JSON.stringify(exif)}
                        color={'secondary'}
                    />
                }
            />
            <Stack py={3} px={1} spacing={2}>
                {[...Object.entries(exif)]
                    .sort((a, b) => a[0].localeCompare(b[0]))
                    .map(([key, value]) =>
                        value ? (
                            <ExifItem key={key}>
                                <Typography
                                    variant="small"
                                    color={'text.muted'}>
                                    {key}
                                </Typography>
                                <Typography
                                    sx={{
                                        width: '100%',
                                        textOverflow: 'ellipsis',
                                        whiteSpace: 'nowrap',
                                        overflow: 'hidden',
                                    }}>
                                    {parseExifValue(value)}
                                </Typography>
                            </ExifItem>
                        ) : (
                            <></>
                        )
                    )}
            </Stack>
        </FileInfoSidebar>
    );
}
