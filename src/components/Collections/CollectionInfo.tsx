import { Box, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import constants from 'utils/strings/constants';
interface Iprops {
    name: string;
    fileCount: number;
    endIcon?: React.ReactNode;
}

export function CollectionInfo({ name, fileCount, endIcon }: Iprops) {
    return (
        <div>
            <FlexWrapper>
                <Typography variant="subtitle">{name}</Typography>
                {endIcon && <Box ml={1.5}>{endIcon}</Box>}
            </FlexWrapper>
            <Typography variant="body2" color="text.secondary">
                {constants.PHOTO_COUNT(fileCount)}
            </Typography>
        </div>
    );
}
