import React from 'react';
import styled from 'styled-components';

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

const CustomH5 = styled.h5<{ color: string }>`
    color: ${(props) => props.color};
    cursor: pointer;
    margin-bottom: 0;
    &:hover {
        text-decoration: underline;
    }
`;

export default function LinkButton(props: LinkButtonProps) {
    return (
        <CustomH5
            color={getVariantColor(props.variant)}
            style={{
                ...props.style,
            }}
            onClick={props?.onClick ?? (() => null)}>
            {props.children}
        </CustomH5>
    );
}
