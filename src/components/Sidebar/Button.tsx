import React from 'react';
import { Button, ButtonProps } from '@mui/material';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
interface IProps {
    children: any;
    bgDark?: boolean;
    hideArrow?: boolean;
    onClick: () => void;
    color?: ButtonProps['color'];
}
export default function SidebarButton({
    children,
    bgDark,
    hideArrow,
    ...props
}: IProps) {
    return (
        <Button
            {...props}
            variant="text"
            sx={{
                width: '100%',
                marginBottom: '16px',
                display: 'flex',
                justifyContent: 'space-between',
                bgcolor: bgDark && 'grey.800',
                padding: '10px',
                borderRadius: '8px',
                fontSize: '18px',
            }}>
            {children}
            {!hideArrow && <NavigateNextIcon />}
        </Button>
    );
}
