import { Button, styled } from '@mui/material';
import { CSSProperties } from '@mui/material/styles/createTypography';

export const Chip = styled(Button)(({ theme }) => ({
    ...(theme.typography.small as CSSProperties),
}));
