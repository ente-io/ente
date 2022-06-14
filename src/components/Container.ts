import { Box } from '@mui/material';
import { styled } from '@mui/material';
import { default as MuiStyled } from '@mui/styled-engine';
import { IMAGE_CONTAINER_MAX_WIDTH } from 'constants/gallery';

const VerticallyCentered = MuiStyled(Box)`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    text-align:center;
    overflow: auto;
`;

export default VerticallyCentered;

export const DisclaimerContainer = styled('div')`
    margin: 16px 0;
    color: rgb(158, 150, 137);
    font-size: 14px;
`;

export const IconButton = styled('button')`
    background: none;
    border: none;
    border-radius: 50%;
    padding: 5px;
    color: inherit;
    margin: 0 10px;
    display: inline-flex;
    align-items: center;
    justify-content: center;

    &:focus,
    &:hover {
        background-color: rgba(255, 255, 255, 0.2);
    }
`;

export const Row = styled('div')`
    min-height: 32px;
    display: flex;
    align-items: center;
    margin-bottom: ${({ theme }) => theme.spacing(2)};
    flex: 1;
`;

export const Label = styled('div')<{ width?: string }>`
    width: ${(props) => props.width ?? '70%'};
    color: ${(props) => props.theme.palette.text.secondary};
`;
export const Value = styled('div')<{ width?: string }>`
    display: flex;
    justify-content: flex-start;
    align-items: center;
    width: ${(props) => props.width ?? '30%'};
`;

export const FlexWrapper = styled(Box)`
    display: flex;
    width: 100%;
    align-items: center;
`;

export const FreeFlowText = styled('div')`
    word-break: break-word;
    min-width: 30%;
    text-align: left;
`;

export const SpaceBetweenFlex = styled(FlexWrapper)`
    justify-content: space-between;
`;

export const CenteredFlex = styled(FlexWrapper)`
    justify-content: center;
`;

export const FluidContainer = styled(FlexWrapper)`
    flex: 1;
`;

export const Overlay = styled(Box)`
    display: flex;
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    z-index: 1; ;
`;

export const InvertedIconButton = styled(IconButton)`
    background-color: ${({ theme }) => theme.palette.primary.main};
    color: ${({ theme }) => theme.palette.background.default};
    &:hover {
        background-color: ${({ theme }) => theme.palette.grey.A100};
    }
    &:focus {
        background-color: ${({ theme }) => theme.palette.primary.main};
    }
`;

export const PaddedContainer = styled(Box)`
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * 4}px) {
        padding: 0 4px;
    }
`;
