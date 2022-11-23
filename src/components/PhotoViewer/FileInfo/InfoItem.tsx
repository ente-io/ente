import Edit from '@mui/icons-material/Edit';
import { Box, IconButton, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';

interface Iprops {
    icon: JSX.Element;
    title?: string;
    caption?: string | JSX.Element;
    openEditor?: any;
    loading?: boolean;
    hideEditOption?: any;
    customEndButton?: any;
    children?: any;
}

export default function InfoItem({
    icon,
    title,
    caption,
    openEditor,
    loading,
    hideEditOption,
    customEndButton,
    children,
}: Iprops): JSX.Element {
    return (
        <FlexWrapper height={48} justifyContent="space-between">
            <FlexWrapper gap={0.5} pr={1}>
                <IconButton
                    color="secondary"
                    sx={{ '&&': { cursor: 'default' } }}
                    disableRipple>
                    {icon}
                </IconButton>
                <Box>
                    {children ? (
                        children
                    ) : (
                        <>
                            <Typography>{title}</Typography>
                            <Typography variant="body2" color="text.secondary">
                                {caption}
                            </Typography>
                        </>
                    )}
                </Box>
            </FlexWrapper>
            {customEndButton
                ? customEndButton
                : !hideEditOption && (
                      <IconButton onClick={openEditor} color="secondary">
                          {!loading ? <Edit /> : <SmallLoadingSpinner />}
                      </IconButton>
                  )}
        </FlexWrapper>
    );
}
