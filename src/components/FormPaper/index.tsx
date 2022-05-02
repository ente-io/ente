import React from 'react';
import { Paper, PaperProps } from '@mui/material';
import { FC } from 'react';

const FormPaper: FC<PaperProps> = ({ sx, children, ...props }) => (
    <Paper sx={{ maxWidth: '360px', py: 4, px: 2, ...sx }} {...props}>
        {children}
    </Paper>
);

export default FormPaper;
