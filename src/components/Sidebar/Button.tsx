import React, { FC } from 'react';
import { Button, ButtonProps, Theme, TypographyVariant } from '@mui/material';
import { FluidContainer } from 'components/Container';
import { SystemStyleObject } from '@mui/system';

type Iprops = ButtonProps<'button', { typographyVariant?: TypographyVariant }>;

const SidebarButton: FC<Iprops> = ({
    children,
    sx,
    typographyVariant = 'body1',
    ...props
}) => {
    return (
        <>
            <Button
                variant="text"
                fullWidth
                sx={(theme) =>
                    ({
                        ...theme.typography[typographyVariant],
                        fontWeight: 'bold',
                        my: 0.5,
                        px: 1,
                        py: '10px',
                        ...sx,
                    } as SystemStyleObject<Theme>)
                }
                {...props}>
                <FluidContainer>{children}</FluidContainer>
            </Button>
        </>
    );
};

export default SidebarButton;
