import React, { FC } from 'react';
import { Typography, TypographyProps } from '@mui/material';

const FormPaperHeaderText: FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography
            css={`
                font-size: 32px;
                font-weight: 600;
                line-height: 40px;
            `}
            sx={{ mb: 8, ...sx }}
            {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperHeaderText;
