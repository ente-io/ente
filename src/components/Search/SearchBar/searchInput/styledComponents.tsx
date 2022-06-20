import { CenteredFlex } from 'components/Container';
import { css, styled } from '@mui/material';

export const SearchInputWrapper = styled(CenteredFlex)<{ isOpen: boolean }>`
    max-width: 484px;
    margin: auto;
    ${(props) =>
        !props.isOpen &&
        css`
            @media (max-width: 624px) {
                display: none;
            }
        `}
`;
