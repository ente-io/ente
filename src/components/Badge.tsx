import { Paper, styled } from '@mui/material';
import { CSSProperties } from '@mui/styled-engine';

export const Badge = styled(Paper)(({ theme }) => ({
    padding: '2px 4px',
    backgroundColor: theme.palette.glass.main,
    color: theme.palette.glass.contrastText,
    textTransform: 'uppercase',
    ...(theme.typography.mini as CSSProperties),
}));
