import {
    Paper,
    Stack,
    styled,
    Typography,
    type TypographyProps,
} from "@mui/material";
import React from "react";
import { isSxArray } from "./utils/sx";

export const FormPaper = styled(Paper)(({ theme }) => ({
    padding: theme.spacing(4, 2),
    maxWidth: "360px",
    width: "100%",
    textAlign: "left",
}));

export const FormPaperTitle: React.FC<TypographyProps> = ({
    sx,
    children,
    ...rest
}) => (
    <Typography
        variant="h2"
        sx={{ mb: 8, ...(sx ? (isSxArray(sx) ? sx : [sx]) : []) }}
        {...rest}
    >
        {children}
    </Typography>
);

export const FormPaperFooter: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Stack
        direction="row"
        sx={{
            mt: 5,
            textAlign: "center",
            justifyContent: "space-evenly",
        }}
    >
        {children}
    </Stack>
);
