import ArrowForward from '@mui/icons-material/ArrowForward';
import { Box, IconButton, styled, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { useTranslation } from 'react-i18next';

const RowContainer = styled(SpaceBetweenFlex)(({ theme }) => ({
    gap: theme.spacing(1.5),
    padding: theme.spacing(1.5, 1),
    cursor: 'pointer',
    '&:hover .endIcon': {
        backgroundColor: 'rgba(255,255,255,0.08)',
    },
}));
export function FreePlanRow({ closeModal }) {
    const { t } = useTranslation();
    return (
        <RowContainer onClick={closeModal}>
            <Box>
                <Typography> {t('FREE_PLAN_OPTION_LABEL')}</Typography>
                <Typography variant="body2" color="text.secondary">
                    {t('FREE_PLAN_DESCRIPTION')}
                </Typography>
            </Box>
            <IconButton className={'endIcon'}>
                <ArrowForward />
            </IconButton>
        </RowContainer>
    );
}
