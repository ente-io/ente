import { Typography, IconButton } from '@mui/material';
import React from 'react';
import constants from 'utils/strings/constants';
import CloseIcon from '@mui/icons-material/Close';
import { SpaceBetweenFlex } from 'components/Container';

interface IProps {
    closeSidebar: () => void;
}

export default function HeaderSection({ closeSidebar }: IProps) {
    return (
        <SpaceBetweenFlex>
            <Typography
                css={`
                    font-size: 18px;
                    font-weight: 600;
                    line-height: 24px;
                `}>
                {constants.ENTE}
            </Typography>
            <IconButton aria-label="close" onClick={closeSidebar}>
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpaceBetweenFlex>
    );
}
