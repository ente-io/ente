import React, { FC } from 'react';
import { Box, ButtonProps } from '@mui/material';
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
            sx={{ px: '12px' }}
            css={`
                font-size: 14px;
                line-height: 20px;
                font-weight: 500;
            `}
            {...props}>
            <Box mr={'12px'}>{icon}</Box>
            {label}
            <DotSeparator />
            <Box component={'span'} sx={{ color: 'text.secondary' }}>
                {count}
            </Box>
        </SidebarButton>
    );
};

export default ShortcutButton;
