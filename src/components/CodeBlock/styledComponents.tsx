import { CenteredFlex } from 'components/Container';
import { Box, styled, Theme } from '@mui/material';
export const Wrapper = styled(CenteredFlex)`
    position: relative;
    background: ${({ theme }: { theme: Theme }) => theme.colors.accent['700']};
    border-radius: ${({ theme }: { theme: Theme }) =>
        theme.shape.borderRadius}px;
    min-height: 80px;
`;
export const CopyButtonWrapper = styled(Box)`
    position: absolute;
    top: 0px;
    right: 0px;
    margin-top: ${({ theme }: { theme: Theme }) => theme.spacing(1)};
`;

export const CodeWrapper = styled('div')`
    padding: 16px 36px 16px 16px;
    border-radius: ${({ theme }: { theme: Theme }) =>
        theme.shape.borderRadius}px;
`;
