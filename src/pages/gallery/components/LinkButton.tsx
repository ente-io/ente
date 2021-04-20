import React from 'react';

enum ButtonVariant {
    success = 'success',
    danger = 'danger',
    secondary = 'secondary',
}
type Props = React.PropsWithChildren<{
    onClick?: any;
    variant?: string;
    style?: any;
}>;

export default function LinkButton(props: Props) {
    function getButtonColor(variant: string) {
        switch (variant) {
            case ButtonVariant.success:
                return '#2dc262';
            case ButtonVariant.danger:
                return '#c93f3f';
            case ButtonVariant.secondary:
                return '#858585';
            default:
                return '#d1d1d1';
        }
    }
    return (
        <h5
            style={{
                color: getButtonColor(props.variant),
                cursor: 'pointer',
                marginTop: '30px',
                ...props.style,
            }}
            onClick={props?.onClick ?? (() => null)}
        >
            {props.children}
        </h5>
    );
}
