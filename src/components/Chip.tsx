import { Box, styled, Theme } from '@mui/material';
import { CSSProperties } from 'react';

export const Chip = styled(Box)(({ theme }: { theme: Theme }) => ({
    ...(theme.typography.small as CSSProperties),
    padding: '8px 12px',
    borderRadius: '4px',
    backgroundColor: theme.colors.fill.faint,
    fontWeight: 'bold',
}));
