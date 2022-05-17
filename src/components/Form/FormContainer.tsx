import React from 'react';
import { ContainerProps } from '@mui/material';
import { FC } from 'react';
import VerticallyCenteredContainer from 'components/Container';

const FormContainer: FC<ContainerProps> = ({ style, children, ...props }) => (
    <VerticallyCenteredContainer
        style={{ alignItems: 'flex-end', textAlign: 'left', ...style }}
        {...props}>
        {children}
    </VerticallyCenteredContainer>
);

export default FormContainer;
