import React, { FC } from 'react';
import { BoxProps } from '@mui/material';
import Container from 'components/Container';

const FormPaperFooter: FC<BoxProps> = ({ sx, style, ...props }) => {
    return (
        <Container
            style={{ flexDirection: 'row', ...style }}
            sx={{
                mt: 3,
                ...sx,
            }}
            {...props}>
            {props.children}
        </Container>
    );
};

export default FormPaperFooter;
