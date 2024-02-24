import { Button, ButtonProps, styled } from "@mui/material";
import { CSSProperties } from "@mui/material/styles/createTypography";

export const MapButton = styled((props: ButtonProps) => (
    <Button color="secondary" {...props} />
))(({ theme }) => ({
    ...(theme.typography.small as CSSProperties),
    padding: "8px",
}));
