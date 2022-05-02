import React, { FC } from 'react';
import { Typography, TypographyProps } from '@mui/material';

const CardTitle: FC<TypographyProps> = (props) => {
    return (
        <Typography
            sx={{
                fontSize: '32px',
                fontWeight: '600',
                textAlign: 'left',
                mb: 8,
            }}
            {...props}>
            {props.children}
        </Typography>
    );
};

export default CardTitle;
