import { Box } from "@mui/material";

export const DialogWarningIllustration: React.FC<{
    color?: "grey" | "red";
}> = ({ color = "grey" }) => (
    <Box
        component="img"
        src={`/images/warning-${color}.png`}
        alt=""
        sx={{ width: 68, height: 64, objectFit: "contain", display: "block" }}
    />
);
