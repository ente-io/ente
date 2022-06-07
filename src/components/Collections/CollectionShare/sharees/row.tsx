import React from 'react';
import { IconButton } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import { User } from 'types/user';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';

interface IProps {
    sharee: User;
    collectionUnshare: (sharee: User) => void;
}
const ShareeRow = ({ sharee, collectionUnshare }: IProps) => (
    <SpaceBetweenFlex>
        {sharee.email}
        <IconButton sx={{ ml: 2 }} onClick={() => collectionUnshare(sharee)}>
            <MoreHorizIcon />
        </IconButton>
    </SpaceBetweenFlex>
);

export default ShareeRow;
