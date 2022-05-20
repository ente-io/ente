import React, { FC } from 'react';
import { Typography, TypographyProps } from '@mui/material';

const FormPaperHeaderText: FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography variant="title" sx={{ mb: 8, ...sx }} {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperHeaderText;
