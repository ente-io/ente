import { Button, type ButtonProps, styled } from "@mui/material";

export const ChipButton = styled((props: ButtonProps) => (
    <Button color="secondary" {...props} />
))(({ theme }) => ({
    ...theme.typography.small,
    padding: "8px",
}));
