import ChevronRight from '@mui/icons-material/ChevronRight';
import { Box, ButtonProps, styled } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';

const ManageSubscriptionButtonBase = styled(Box)<{
    color?: ButtonProps['color'];
}>(({ theme, color = 'primary' }) => ({
    textDecoration: 'none',
    padding: '20px 24px',
    width: '100%',
    border: `1px solid ${theme.palette.divider}`,
    borderTop: '0.5px',
    '&:hover .children': {
        color: theme.palette[color].main,
        cursor: 'pointer',
    },
    '&:last-of-type': {
        borderRadius: '0 0 8px 8px',
    },
}));

const ManageSubscriptionButton = ({ children, ...props }) => (
    <ManageSubscriptionButtonBase {...props}>
        <FlexWrapper>
            <div className="children">{children}</div>
            <ChevronRight />
        </FlexWrapper>
    </ManageSubscriptionButtonBase>
);

export default ManageSubscriptionButton;
