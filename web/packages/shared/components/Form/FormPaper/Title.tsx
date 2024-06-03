import { Typography, type TypographyProps } from "@mui/material";
import React from "react";

const FormPaperTitle: React.FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography variant="h2" sx={{ mb: 8, ...sx }} {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperTitle;
