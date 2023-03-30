import { styled, Theme } from '@mui/material';
export const ManageSectionLabel = styled('summary')(
    ({ theme }: { theme: Theme }) => `
    text-align: center;
    margin-bottom:${theme.spacing(1)};
`
);

export const ManageSectionOptions = styled('section')(
    ({ theme }: { theme: Theme }) => `
    margin-bottom:${theme.spacing(4)};
`
);
