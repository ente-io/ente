import { Typography, type TypographyProps } from "@mui/material";
import React from "react";

const InvalidInputMessage: React.FC<TypographyProps> = (props) => {
    return (
        <Typography
            variant="mini"
            sx={{
                color: (theme) => theme.colors.danger.A700,
            }}
            {...props}
        >
            {props.children}
        </Typography>
    );
};

export default InvalidInputMessage;
