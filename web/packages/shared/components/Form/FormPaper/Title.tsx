import { Typography, TypographyProps } from "@mui/material";
import { FC } from "react";

const FormPaperTitle: FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography variant="h2" sx={{ mb: 8, ...sx }} {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperTitle;
