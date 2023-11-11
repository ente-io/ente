import ArrowForward from '@mui/icons-material/ArrowForward';
import { Box, IconButton, styled, Typography } from '@mui/material';
import { SpaceBetweenFlex } from '@ente/shared/components/Container';
import React from 'react';
import { t } from 'i18next';

const RowContainer = styled(SpaceBetweenFlex)(({ theme }) => ({
    gap: theme.spacing(1.5),
    padding: theme.spacing(1.5, 1),
    cursor: 'pointer',
    '&:hover .endIcon': {
        backgroundColor: 'rgba(255,255,255,0.08)',
    },
}));
export function FreePlanRow({ closeModal }) {
    return (
        <RowContainer onClick={closeModal}>
            <Box>
                <Typography> {t('FREE_PLAN_OPTION_LABEL')}</Typography>
                <Typography variant="small" color="text.muted">
                    {t('FREE_PLAN_DESCRIPTION')}
                </Typography>
            </Box>
            <IconButton className={'endIcon'}>
                <ArrowForward />
            </IconButton>
        </RowContainer>
    );
}
