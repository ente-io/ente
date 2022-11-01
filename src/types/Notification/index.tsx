import { ButtonProps } from '@mui/material/Button';
import { ReactNode } from 'react';

export interface NotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps['color'];
    message: JSX.Element | string;
    subtext?: JSX.Element | string;
    onClick?: () => void;
    endIcon?: ReactNode;
}

export type SetNotificationAttributes = React.Dispatch<
    React.SetStateAction<NotificationAttributes>
>;
