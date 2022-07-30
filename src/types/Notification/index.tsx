import { ButtonProps } from '@mui/material/Button';
import { ReactNode } from 'react';

export interface NotificationAttributes {
    icon?: ReactNode;
    variant: ButtonProps['color'];
    message: JSX.Element | string;
    action?: {
        text: string;
        callback: () => void;
    };
}
