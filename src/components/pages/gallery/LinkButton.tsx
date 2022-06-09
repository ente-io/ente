import { Link, LinkProps } from '@mui/material';
import React, { FC } from 'react';
import { ButtonProps } from 'react-bootstrap';

export enum ButtonVariant {
    success = 'success',
    danger = 'danger',
    secondary = 'secondary',
    warning = 'warning',
}
export type LinkButtonProps = React.PropsWithChildren<{
    onClick: () => void;
    variant?: string;
    style?: React.CSSProperties;
}>;

export function getVariantColor(variant: string) {
    switch (variant) {
        case ButtonVariant.success:
            return '#51cd7c';
        case ButtonVariant.danger:
            return '#c93f3f';
        case ButtonVariant.secondary:
            return '#858585';
        case ButtonVariant.warning:
            return '#D7BB63';
        default:
            return '#d1d1d1';
    }
}

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
                '&:hover': {
                    color: `${color}.main`,
                },
                ...sx,
            }}
            {...props}>
            {children}
        </Link>
    );
};

export default LinkButton;
