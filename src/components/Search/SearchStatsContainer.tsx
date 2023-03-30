import { styled, Theme } from '@mui/material';
const SearchStatsContainer = styled('div')(
    ({ theme }: { theme: Theme }) => `
    display: flex;
    justify-content: center;
    align-items: center;
    color: #979797;
    margin: ${theme.spacing(1, 0)};
`
);

export default SearchStatsContainer;
