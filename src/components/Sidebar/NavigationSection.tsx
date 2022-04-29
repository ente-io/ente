import React, { useContext } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import { GalleryContext } from 'pages/gallery';
import { ARCHIVE_SECTION, TRASH_SECTION } from 'constants/collection';
import DeleteIcon from '@mui/icons-material/Delete';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import { Box, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import { CollectionSummaries } from 'types/collection';

interface Iprops {
    closeSidebar: () => void;
    collectionSummaries: CollectionSummaries;
}

const DotSeparator = () => (
    <Typography color="text.secondary" ml="10px" mr="10px" fontWeight={700}>
        {'·'}
    </Typography>
);
export default function NavigationSection({
    closeSidebar,
    collectionSummaries,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);
    const openArchiveSection = () => {
        galleryContext.setActiveCollection(ARCHIVE_SECTION);
        closeSidebar();
    };

    const openTrashSection = () => {
        galleryContext.setActiveCollection(TRASH_SECTION);
        closeSidebar();
    };
    return (
        <>
            <SidebarButton bgDark onClick={openTrashSection}>
                <FlexWrapper>
                    <Box mr="10px">
                        <DeleteIcon />
                    </Box>

                    {constants.TRASH}
                    <DotSeparator />
                    <Typography color="text.secondary">
                        {collectionSummaries.get(TRASH_SECTION).fileCount}
                    </Typography>
                </FlexWrapper>
            </SidebarButton>
            <SidebarButton bgDark onClick={openArchiveSection}>
                <FlexWrapper>
                    <Box mr="10px">
                        <VisibilityOffIcon />
                    </Box>

                    {constants.ARCHIVE}
                    <DotSeparator />
                    <Typography color="text.secondary">
                        {collectionSummaries.get(ARCHIVE_SECTION).fileCount}
                    </Typography>
                </FlexWrapper>
            </SidebarButton>
        </>
    );
}
