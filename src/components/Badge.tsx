import { Paper, styled } from '@mui/material';
import { CSSProperties } from '@mui/styled-engine';

export const Badge = styled(Paper)(({ theme }) => ({
    padding: '2px 4px',
    backgroundColor: theme.palette.backdrop.main,
    filter: `blur(${theme.palette.blur.muted})`,
    color: theme.palette.primary.contrastText,
    textTransform: 'uppercase',
    ...(theme.typography.mini as CSSProperties),
}));
