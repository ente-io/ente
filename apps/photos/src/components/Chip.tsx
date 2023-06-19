import { Button, styled } from '@mui/material';
import { CSSProperties } from '@mui/material/styles/createTypography';

export const Chip = styled((props) => <Button color="secondary" {...props} />)(
    ({ theme }) => ({
        ...(theme.typography.small as CSSProperties),
        padding: '8px',
    })
);
