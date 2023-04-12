import { styled } from '@mui/material';

export const MenuItemGroup = styled('div')(
    ({ theme }) => `
    & > .MuiMenuItem-root{
        border-radius: 8px; 
    }
    & > .MuiMenuItem-root:not(:last-of-type) {
        border-bottom-left-radius: 0;
        border-bottom-right-radius: 0;
    }
    & > .MuiMenuItem-root:not(:first-of-type) {
        border-top-left-radius: 0;
        border-top-right-radius: 0;
    }
    background-color: ${theme.colors.background.elevated2};
    border-radius: 8px;
`
);
