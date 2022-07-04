import { Box, Typography } from '@mui/material';
import React from 'react';
import { makeHumanReadableStorage } from 'utils/billing';
import constants from 'utils/strings/constants';

interface Iprops {
    usage: number;
    storage: number;
}
export default function StorageSection({ usage, storage }: Iprops) {
    return (
        <Box width="100%">
            <Typography variant="body2" color={'text.secondary'}>
                {constants.STORAGE}
            </Typography>

            <Typography
                fontWeight={'bold'}
                sx={{ fontSize: '24px', lineHeight: '30px' }}>
                {`${makeHumanReadableStorage(storage - usage)} ${
                    constants.OF
                } ${makeHumanReadableStorage(storage)} ${constants.FREE}`}
            </Typography>
        </Box>
    );
}
