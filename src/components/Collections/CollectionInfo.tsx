import { Typography } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
export function CollectionInfo({ name, fileCount }) {
    return (
        <div>
            <Typography
                css={`
                    font-size: 24px;
                    font-weight: 600;
                    line-height: 36px;
                `}>
                {name}
            </Typography>
            <Typography
                css={`
                    font-size: 14px;
                    line-height: 20px;
                `}>
                {constants.PHOTO_COUNT(fileCount)}
            </Typography>
        </div>
    );
}
