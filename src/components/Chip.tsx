import { Box, styled } from '@mui/material';
import { CSSProperties } from 'react';

export const Chip = styled(Box)(({ theme }) => ({
    ...(theme.typography.body2 as CSSProperties),
    padding: '8px 12px',
    borderRadius: '4px',
    backgroundColor: theme.palette.fill.dark,
    fontWeight: 'bold',
}));
