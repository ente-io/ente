import React, { FC } from 'react';
import { Box, ButtonProps } from '@mui/material';
import SidebarButton from './Button';
import { DotSeparator } from './styledComponents';
import { formatNumber } from 'utils/number/format';

type Iprops = ButtonProps<
    'button',
    { label: JSX.Element | string; count: number }
>;

const ShortcutButton: FC<ButtonProps<'button', Iprops>> = ({
    label,
    count,
    ...props
}) => {
    return (
        <SidebarButton
            variant="contained"
            color="secondary"
            sx={{ fontWeight: 'normal' }}
            {...props}>
            {label}

            <Box sx={{ color: 'text.muted' }}>
                <DotSeparator />
                {formatNumber(count)}
            </Box>
        </SidebarButton>
    );
};

export default ShortcutButton;
