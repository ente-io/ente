import React from 'react';
import { ContainerProps } from '@mui/material';
import { FC } from 'react';
import Container from 'components/Container';

const FormContainer: FC<ContainerProps> = ({ style, children, ...props }) => (
    <Container
        style={{ alignItems: 'flex-end', textAlign: 'left', ...style }}
        {...props}>
        {children}
    </Container>
);

export default FormContainer;
