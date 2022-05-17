import { Box } from '@mui/material';
import styled from 'styled-components';
import { default as MuiStyled } from '@mui/styled-engine';

const VerticallyCenteredContainer = MuiStyled(Box)`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    text-align:center;
    overflow: auto;
`;

export default VerticallyCenteredContainer;

export const DisclaimerContainer = styled.div`
    margin: 16px 0;
    color: rgb(158, 150, 137);
    font-size: 14px;
`;

export const IconButton = styled.button`
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

export const Row = styled.div`
    display: flex;
    align-items: center;
    margin-bottom: 20px;
    flex: 1;
`;

export const Label = styled.div<{ width?: string }>`
    width: ${(props) => props.width ?? '70%'};
`;
export const Value = styled.div<{ width?: string }>`
    display: flex;
    justify-content: flex-start;
    align-items: center;
    width: ${(props) => props.width ?? '30%'};

    color: #ddd;
`;

export const FlexWrapper = styled(Box)`
    display: flex;
    align-items: center;
`;

export const FreeFlowText = styled.div`
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
