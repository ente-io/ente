import { CenteredFlex } from 'components/Container';
import { Box, styled } from '@mui/material';
export const Wrapper = styled(CenteredFlex)`
    position: relative;
    background: ${({ theme }) => theme.palette.accent.dark};
    border-radius: ${({ theme }) => theme.shape.borderRadius}px;
    min-height: 80px;
`;
export const CopyButtonWrapper = styled(Box)`
    position: absolute;
    top: 0px;
    right: 0px;
`;

export const CodeWrapper = styled('div')`
    padding: 16px 36px 16px 16px;
    border-radius: ${({ theme }) => theme.shape.borderRadius}px;
`;
