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
                size="large"
                sx={(theme) =>
                    ({
                        ...theme.typography[typographyVariant],
                        fontWeight: 'bold',
                        px: 1.5,
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
