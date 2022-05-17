import React from 'react';
import { ContainerProps } from '@mui/material';
import { FC } from 'react';
import VerticallyCentered from 'components/Container';

const FormContainer: FC<ContainerProps> = ({ style, children, ...props }) => (
    <VerticallyCentered
        style={{ alignItems: 'flex-end', textAlign: 'left', ...style }}
        {...props}>
        {children}
    </VerticallyCentered>
);

export default FormContainer;
