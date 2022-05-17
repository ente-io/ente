import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import { GalleryContext } from 'pages/gallery';
import { ARCHIVE_SECTION, TRASH_SECTION } from 'constants/collection';
import DeleteIcon from '@mui/icons-material/Delete';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import { CollectionSummaries } from 'types/collection';
import NavigationButton from './NavigationButton';
interface Iprops {
    closeSidebar: () => void;
    collectionSummaries: CollectionSummaries;
}

export default function NavigationSection({
    closeSidebar,
    collectionSummaries,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);

    const openTrashSection = () => {
        galleryContext.setActiveCollection(TRASH_SECTION);
        closeSidebar();
    };

    const openArchiveSection = () => {
        galleryContext.setActiveCollection(ARCHIVE_SECTION);
        closeSidebar();
    };

    return (
        <>
            <NavigationButton
                icon={<DeleteIcon />}
                label={constants.TRASH}
                count={collectionSummaries.get(TRASH_SECTION)?.fileCount}
                onClick={openTrashSection}
            />
            <NavigationButton
                icon={<VisibilityOffIcon />}
                label={constants.ARCHIVE}
                count={collectionSummaries.get(ARCHIVE_SECTION)?.fileCount}
                onClick={openArchiveSection}
            />
        </>
    );
}
