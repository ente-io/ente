import {
    CenteredFlex,
    FlexWrapper,
    FluidContainer,
} from 'components/Container';
import { css, styled } from '@mui/material';
import { SpecialPadding } from 'styles/SpecialPadding';

export const SearchBarWrapper = styled(FlexWrapper)`
    ${SpecialPadding}
`;

export const SearchMobileBox = styled(FluidContainer)`
    display: flex;
    cursor: pointer;
    align-items: center;
    justify-content: flex-end;
    @media (min-width: 625px) {
        display: none;
    }
`;

export const SearchInputWrapper = styled(CenteredFlex)<{ isOpen: boolean }>`
    background: ${({ theme }) => theme.palette.background.default};
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
