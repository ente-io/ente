import React from 'react';
import { FC } from 'react';
import VerticallyCentered from 'components/Container';
import { BoxProps } from '@mui/system';

const FormContainer: FC<BoxProps> = ({ children, ...props }) => (
    <VerticallyCentered
        sx={{ '&&': { alignItems: 'flex-end', textAlign: 'left' } }}
        {...props}>
        {children}
    </VerticallyCentered>
);

export default FormContainer;
