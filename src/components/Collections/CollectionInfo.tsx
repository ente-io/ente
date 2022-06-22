import { Typography } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
export function CollectionInfo({ name, fileCount }) {
    return (
        <div>
            <Typography variant="subtitle">{name}</Typography>
            <Typography variant="body2" color="text.secondary">
                {constants.PHOTO_COUNT(fileCount)}
            </Typography>
        </div>
    );
}
