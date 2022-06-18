import { styled } from '@mui/material';

const PlanTile = styled('div')<{ current: boolean }>(({ theme, current }) => ({
    padding: theme.spacing(3),
    border: `1px solid ${theme.palette.divider}`,

    '&:hover': {
        backgroundColor: ' rgba(40, 214, 101, 0.11)',
        cursor: 'pointer',
    },
    ...(current && {
        borderColor: theme.palette.accent.main,
        cursor: 'not-allowed',
        '&:hover': { backgroundColor: 'transparent' },
    }),
    width: ' 260px',
    borderRadius: '8px 8px 0 0',
    '&:not(:first-of-type)': {
        borderTopLeftRadius: '0',
    },

    '&:not(:last-of-type)': {
        borderTopRightRadius: '0',
    },
}));

export default PlanTile;
