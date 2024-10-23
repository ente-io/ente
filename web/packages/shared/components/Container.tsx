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

export const SpaceBetweenFlex = styled(FlexWrapper)`
    justify-content: space-between;
`;

/**
 * Deprecated, use {@link CenteredFlex} from @/base/components/mui/container
 * instead
 */
export const CenteredFlex = styled(FlexWrapper)`
    justify-content: center;
`;

export const FluidContainer = styled(FlexWrapper)`
    flex: 1;
`;

export const Overlay = styled(Box)`
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
`;

export const HorizontalFlex = styled(Box)({
    display: "flex",
});

export const VerticallyCenteredFlex = styled(HorizontalFlex)({
    alignItems: "center",
    display: "flex",
});
