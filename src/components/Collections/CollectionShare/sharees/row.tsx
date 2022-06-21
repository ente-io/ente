import React from 'react';
import { SpaceBetweenFlex } from 'components/Container';
import { User } from 'types/user';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import OverflowMenu from 'components/OverflowMenu/menu';

import NotInterestedIcon from '@mui/icons-material/NotInterested';
import constants from 'utils/strings/constants';
import { OverflowMenuOption } from 'components/OverflowMenu/option';

interface IProps {
    sharee: User;
    collectionUnshare: (sharee: User) => void;
}
const ShareeRow = ({ sharee, collectionUnshare }: IProps) => {
    const handleClick = () => collectionUnshare(sharee);
    return (
        <SpaceBetweenFlex>
            {sharee.email}
            <OverflowMenu
                ariaControls={`email-share-${sharee.email}`}
                menuTriggerIcon={<MoreHorizIcon />}>
                <OverflowMenuOption
                    color="danger"
                    onClick={handleClick}
                    startIcon={<NotInterestedIcon />}
                    label={constants.REMOVE}
                />
            </OverflowMenu>
        </SpaceBetweenFlex>
    );
};

export default ShareeRow;
