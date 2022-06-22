import { FlexWrapper, FluidContainer } from 'components/Container';
import { styled } from '@mui/material';
import { SpecialPadding } from 'styles/SpecialPadding';

export const SearchBarWrapper = styled(FlexWrapper)`
    ${SpecialPadding}
`;

export const SearchButtonWrapper = styled(FluidContainer)`
    display: flex;
    cursor: pointer;
    align-items: center;
    justify-content: flex-end;
    min-height: 64px;
    @media (min-width: 624px) {
        display: none;
    }
`;
