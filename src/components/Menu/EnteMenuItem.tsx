import { MenuItem, ButtonProps, Box } from '@mui/material';
import PublicShareSwitch from 'components/Collections/CollectionShare/publicShare/switch';
import { SpaceBetweenFlex, VerticallyCenteredFlex } from 'components/Container';
import React from 'react';

interface Iprops {
    onClick: () => void;
    color?: ButtonProps['color'];
    startIcon?: React.ReactNode;
    endIcon?: React.ReactNode;
    children?: any;
    hasSwitch?: boolean;
    checked?: boolean;
}
export function EnteMenuItem({
    onClick,
    color = 'primary',
    startIcon,
    endIcon,
    children,
    hasSwitch = false,
    checked,
}: Iprops) {
    const handleClick = () => {
        onClick();
    };

    return (
        <MenuItem
            onClick={handleClick}
            sx={{
                minWidth: '220px',
                color: (theme) => theme.palette[color].main,
                backgroundColor: (theme) => theme.colors.background.elevated2,
                '& .MuiSvgIcon-root': {
                    fontSize: '20px',
                },
                p: 0,
                borderRadius: '4px',
            }}>
            <SpaceBetweenFlex sx={{ pl: '16px', pr: '12px' }}>
                <VerticallyCenteredFlex sx={{ py: '14px' }} gap={'10px'}>
                    {startIcon && startIcon}
                    <Box px={'2px'}>{children}</Box>
                </VerticallyCenteredFlex>
                <VerticallyCenteredFlex gap={'4px'}>
                    {endIcon && endIcon}
                    {hasSwitch && (
                        <PublicShareSwitch
                            checked={checked}
                            onChange={handleClick}
                        />
                    )}
                </VerticallyCenteredFlex>
            </SpaceBetweenFlex>
        </MenuItem>
    );
}
