import React from 'react';
import { SpaceBetweenFlex } from 'components/Container';
import { User } from 'types/user';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import OverflowMenu from 'components/OverflowMenu/menu';

import NotInterestedIcon from '@mui/icons-material/NotInterested';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import { useTranslation } from 'react-i18next';

interface IProps {
    sharee: User;
    collectionUnshare: (sharee: User) => void;
}
const ShareeRow = ({ sharee, collectionUnshare }: IProps) => {
    const { t } = useTranslation();
    const handleClick = () => collectionUnshare(sharee);
    return (
        <SpaceBetweenFlex>
            {sharee.email}
            <OverflowMenu
                menuPaperProps={{
                    sx: {
                        backgroundColor: (theme) =>
                            theme.palette.background.overPaper,
                    },
                }}
                ariaControls={`email-share-${sharee.email}`}
                triggerButtonIcon={<MoreHorizIcon />}>
                <OverflowMenuOption
                    color="danger"
                    onClick={handleClick}
                    startIcon={<NotInterestedIcon />}>
                    {t('REMOVE')}
                </OverflowMenuOption>
            </OverflowMenu>
        </SpaceBetweenFlex>
    );
};

export default ShareeRow;
