import Edit from '@mui/icons-material/Edit';
import { Box, IconButton, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';

export default function InfoItem({
    icon,
    title,
    caption,
    openEditor,
    loading,
    showEditOption,
}) {
    return (
        <FlexWrapper height={48} justifyContent="space-between">
            <FlexWrapper gap={0.5} pr={1}>
                <IconButton
                    color="secondary"
                    sx={{ cursor: 'default' }}
                    disableRipple>
                    {icon}
                </IconButton>
                <Box>
                    <Typography>{title}</Typography>
                    <Typography variant="body2" color="text.secondary">
                        {caption}
                    </Typography>
                </Box>
            </FlexWrapper>
            {showEditOption && (
                <IconButton onClick={openEditor}>
                    {loading ? <SmallLoadingSpinner /> : <Edit />}
                </IconButton>
            )}
        </FlexWrapper>
    );
}
