import React, { useContext } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import { GalleryContext } from 'pages/gallery';
import { ARCHIVE_SECTION, TRASH_SECTION } from 'constants/collection';

export default function NavigationSection({ closeSidebar }) {
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
            <SidebarButton bgDark onClick={openArchiveSection}>
                {constants.ARCHIVE}
            </SidebarButton>
            <SidebarButton bgDark onClick={openTrashSection}>
                {constants.TRASH}
            </SidebarButton>
        </>
    );
}
