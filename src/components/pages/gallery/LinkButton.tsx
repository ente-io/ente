import React from 'react';

export enum ButtonVariant {
    success = 'success',
    danger = 'danger',
    secondary = 'secondary',
    warning = 'warning',
}
type Props = React.PropsWithChildren<{
    onClick: any;
    variant?: string;
    style?: any;
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
export default function LinkButton(props: Props) {
    return (
        <h5
            style={{
                color: getVariantColor(props.variant),
                cursor: 'pointer',
                marginBottom: 0,
                ...props.style,
            }}
            onClick={props?.onClick ?? (() => null)}>
            {props.children}
        </h5>
    );
}
