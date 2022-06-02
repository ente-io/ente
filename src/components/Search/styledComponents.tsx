import {
    CenteredFlex,
    FlexWrapper,
    FluidContainer,
} from 'components/Container';
import styled, { css } from 'styled-components';

export const SearchBarWrapper = styled(CenteredFlex)<{ isOpen: boolean }>`
    ${(props) =>
        !props.isOpen &&
        css`
            @media (max-width: 624px) {
                display: none;
            }
        `}
`;

export const SearchButtonWrapper = styled(FluidContainer)`
    display: flex;
    cursor: pointer;
    align-items: center;
    justify-content: flex-end;
    min-height: 64px;
    padding: 0 20px;
    @media (min-width: 624px) {
        display: none;
    }
`;

export const SearchInputWrapper = styled(FlexWrapper)`
    max-width: 484px;
    margin: auto;
`;
