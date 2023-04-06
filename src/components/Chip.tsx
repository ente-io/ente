import { Box, styled } from '@mui/material';

export const Chip = styled(Box)(({ theme }) => ({
    ...theme.typography.body2,
    padding: '8px 12px',
    borderRadius: '4px',
    backgroundColor: theme.palette.fill.dark,
    fontWeight: 'bold',
}));
