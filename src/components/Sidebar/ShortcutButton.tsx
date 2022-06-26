import React, { FC } from 'react';
import { Box, ButtonProps, Typography } from '@mui/material';
import SidebarButton from './Button';
import { DotSeparator } from './styledComponents';

interface IProps {
    hideArrow?: boolean;
    icon: JSX.Element;
    label: JSX.Element | string;
    count: number;
}
const ShortcutButton: FC<ButtonProps<'button', IProps>> = ({
    icon,
    label,
    count,
    ...props
}) => {
    return (
        <SidebarButton
            variant="contained"
            color="secondary"
            sx={{ px: 1.5 }}
            {...props}>
            <Typography variant="body2" display={'flex'} alignItems="center">
                <Box mr={1.5}>{icon}</Box>
                {label}
                {count > 0 && (
                    <Box sx={{ color: 'text.secondary' }}>
                        <DotSeparator />
                        {count}
                    </Box>
                )}
            </Typography>
        </SidebarButton>
    );
};

export default ShortcutButton;
