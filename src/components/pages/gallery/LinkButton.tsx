import { ButtonProps, Link, LinkProps } from '@mui/material';
import React, { FC } from 'react';

export type LinkButtonProps = React.PropsWithChildren<{
    onClick: () => void;
    variant?: string;
    style?: React.CSSProperties;
}>;

const LinkButton: FC<LinkProps<'button', { color?: ButtonProps['color'] }>> = ({
    children,
    sx,
    color,
    ...props
}) => {
    return (
        <Link
            component="button"
            sx={{
                color: 'text.base',
                textDecoration: 'underline rgba(255, 255, 255, 0.4)',
                paddingBottom: 0.5,
                '&:hover': {
                    color: `${color}.main`,
                    textDecoration: `underline `,
                    textDecorationColor: `${color}.main`,
                },
                ...sx,
            }}
            {...props}>
            {children}
        </Link>
    );
};

export default LinkButton;
