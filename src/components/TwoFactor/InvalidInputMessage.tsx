import React from 'react';
import { TypographyProps, Typography } from '@mui/material';
import { FC } from 'react';

const InvalidInputMessage: FC<TypographyProps> = (props) => {
    return (
        <Typography
            variant="mini"
            sx={{
                color: (theme) => theme.colors.danger.A500,
            }}
            {...props}>
            {props.children}
        </Typography>
    );
};

export default InvalidInputMessage;
