import {
    CenteredFlex,
    FlexWrapper,
    FluidContainer,
} from '@ente/shared/components/Container';
import { css, styled } from '@mui/material';
import { IMAGE_CONTAINER_MAX_WIDTH, MIN_COLUMNS } from 'constants/gallery';

export const SearchBarWrapper = styled(FlexWrapper)`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
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
    background: ${({ theme }) => theme.colors.background.base};
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
