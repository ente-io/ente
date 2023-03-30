import { Box, styled, Theme } from '@mui/material';

export const DashedBorderWrapper = styled(Box)(
    ({ theme }: { theme: Theme }) => ({
        border: `1px dashed ${theme.palette.grey.A400}`,
        borderRadius: theme.spacing(1),
    })
);
