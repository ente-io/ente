import React, { FC } from 'react';
import { Button, ButtonProps, Theme, TypographyProps } from '@mui/material';
import { FluidContainer } from 'components/Container';
import { SystemStyleObject } from '@mui/system';

export type SidebarButtonProps = ButtonProps<
    'button',
    { typographyVariant?: TypographyProps['variant'] }
>;

const SidebarButton: FC<SidebarButtonProps> = ({
    children,
    sx,
    typographyVariant = 'body',
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
