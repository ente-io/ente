import { Box, styled } from "@mui/material";
import { CSSProperties } from "@mui/material/styles/createTypography";

export const Badge = styled(Box)(({ theme }) => ({
    borderRadius: theme.shape.borderRadius,
    padding: "2px 4px",
    backgroundColor: theme.colors.black.muted,
    backdropFilter: `blur(${theme.colors.blur.muted})`,
    color: theme.colors.white.base,
    textTransform: "uppercase",
    ...(theme.typography.tiny as CSSProperties),
}));
