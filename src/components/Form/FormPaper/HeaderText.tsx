import React, { FC } from 'react';
import { Typography, TypographyProps } from '@mui/material';

const FormPaperHeaderText: FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography
            sx={{
                fontSize: '32px',
                fontWeight: '600',
                textAlign: 'left',
                mb: 8,
                ...sx,
            }}
            {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperHeaderText;
