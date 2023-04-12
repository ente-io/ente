import { styled } from '@mui/material';

export const EnteMenuItemGroup = styled('div')(
    ({ theme }) => `
    & > .MuiMenuItem-root:not(:last-of-type) {
        border-bottom-left-radius: 0;
        border-bottom-right-radius: 0;
    }
    & > .MuiMenuItem-root:not(:first-of-type) {
        border-top-left-radius: 0;
        border-top-right-radius: 0;
    }
    background-color: ${theme.palette.background.elevated2};
    border-radius: 4px;
`
);
