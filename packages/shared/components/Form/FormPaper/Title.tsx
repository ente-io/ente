import { FC } from 'react';
import { Typography, TypographyProps } from '@mui/material';

const FormPaperTitle: FC<TypographyProps> = ({ sx, ...props }) => {
    return (
        <Typography variant="h2" sx={{ mb: 8, ...sx }} {...props}>
            {props.children}
        </Typography>
    );
};

export default FormPaperTitle;
