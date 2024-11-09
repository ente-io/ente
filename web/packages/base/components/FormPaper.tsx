import { VerticallyCentered } from "@ente/shared/components/Container";
import {
    Divider,
    Paper,
    styled,
    Typography,
    type BoxProps,
    type TypographyProps,
} from "@mui/material";
import React from "react";

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

export const FormPaperFooter: React.FC<BoxProps> = ({
    sx,
    style,
    ...props
}) => {
    return (
        <>
            <Divider />
            <VerticallyCentered
                style={{ flexDirection: "row", ...style }}
                sx={{
                    mt: 3,
                    ...sx,
                }}
                {...props}
            >
                {props.children}
            </VerticallyCentered>
        </>
    );
};
