import { Typography, TypographyProps, styled } from '@mui/material';

export const Chip = styled((props: TypographyProps) => (
    <Typography variant="small" {...props} />
))(({ theme }) => ({
    padding: '8px 12px',
    borderRadius: '4px',
    backgroundColor: theme.colors.fill.faint,
    fontWeight: 'bold',
}));
