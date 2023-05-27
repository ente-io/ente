import React, { FC } from 'react';
import { BoxProps, Divider } from '@mui/material';
import { VerticallyCentered } from 'components/Container';

const FormPaperFooter: FC<BoxProps> = ({ sx, style, ...props }) => {
    return (
        <>
            <Divider />
            <VerticallyCentered
                style={{ flexDirection: 'row', ...style }}
                sx={{
                    mt: 3,
                    ...sx,
                }}
                {...props}>
                {props.children}
            </VerticallyCentered>
        </>
    );
};

export default FormPaperFooter;
