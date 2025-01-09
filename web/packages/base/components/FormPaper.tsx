import { VerticallyCentered } from "@ente/shared/components/Container";
import {
    Divider,
    Paper,
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

export const FormPaperTitle: React.FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography variant="h2" sx={{ mb: 8, ...sx }} {...props}>
            {props.children}
        </Typography>
    );
};

export const FormPaperFooter: React.FC<
    React.PropsWithChildren<{ sx?: TypographyProps["sx"] }>
> = ({ sx, children }) => (
    <>
        <Divider />
        <VerticallyCentered
            sx={[
                { mt: 3, flexDirection: "row" },
                ...(sx ? (isSxArray(sx) ? sx : [sx]) : []),
            ]}
        >
            {children}
        </VerticallyCentered>
    </>
);
