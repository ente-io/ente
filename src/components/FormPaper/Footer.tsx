import React, { FC } from 'react';
import { ContainerProps } from '@mui/material';
import Container from 'components/Container';

const FormPaperFooter: FC<ContainerProps> = ({ sx, style, ...props }) => {
    return (
        <Container
            disableGutters
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
