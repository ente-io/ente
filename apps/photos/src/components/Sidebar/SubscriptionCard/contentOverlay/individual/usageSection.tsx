import { Box, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { makeHumanReadableStorage } from 'utils/billing';
import { t } from 'i18next';

import { Progressbar } from '../../styledComponents';

interface Iprops {
    usage: number;
    fileCount: number;
    storage: number;
}
export function IndividualUsageSection({ usage, storage, fileCount }: Iprops) {
    return (
        <Box width="100%">
            <Progressbar value={Math.min((usage * 100) / storage, 100)} />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}>
                <Typography variant="mini">{`${makeHumanReadableStorage(
                    storage - usage
                )} ${t('FREE')}`}</Typography>
                <Typography variant="mini" fontWeight={'bold'}>
                    {t('photos_count', { count: fileCount ?? 0 })}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
}
