import { Box, styled } from '@mui/material';
import { CSSProperties } from '@mui/material/styles/createTypography';

export const Chip = styled(Box)(({ theme }) => ({
    ...(theme.typography.small as CSSProperties),
    padding: '8px 12px',
    borderRadius: '4px',
    backgroundColor: theme.colors.fill.faint,
    fontWeight: 'bold',
}));
