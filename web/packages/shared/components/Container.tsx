import { Box, styled } from "@mui/material";

export const VerticallyCentered = styled(Box)`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    text-align: center;
    overflow: auto;
`;

export const FlexWrapper = styled(Box)`
    display: flex;
    width: 100%;
    align-items: center;
`;

/**
 * Deprecated, use {@link SpacedRow} from ente-base/components/mui/container
 * instead
 */
export const SpaceBetweenFlex = styled(FlexWrapper)`
    justify-content: space-between;
`;
