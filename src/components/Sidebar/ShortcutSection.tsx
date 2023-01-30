import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import { GalleryContext } from 'pages/gallery';
import {
    ARCHIVE_SECTION,
    TRASH_SECTION,
    UNCATEGORIZED_SECTION,
} from 'constants/collection';
import { CollectionSummaries } from 'types/collection';
import ShortcutButton from './ShortcutButton';
import DeleteOutline from '@mui/icons-material/DeleteOutline';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import CategoryIcon from '@mui/icons-material/Category';
import { getUncategorizedCollection } from 'services/collectionService';
interface Iprops {
    closeSidebar: () => void;
    collectionSummaries: CollectionSummaries;
}

export default function ShortcutSection({
    closeSidebar,
    collectionSummaries,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);

    const openUncategorizedSection = async () => {
        const uncategorisedCollection = await getUncategorizedCollection();
        galleryContext.setActiveCollection(uncategorisedCollection.id);
        closeSidebar();
    };

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
            <ShortcutButton
                startIcon={<CategoryIcon />}
                label={constants.UNCATEGORIZED}
                count={
                    collectionSummaries.get(UNCATEGORIZED_SECTION)?.fileCount
                }
                onClick={openUncategorizedSection}
            />
            <ShortcutButton
                startIcon={<DeleteOutline />}
                label={constants.TRASH}
                count={collectionSummaries.get(TRASH_SECTION)?.fileCount}
                onClick={openTrashSection}
            />
            <ShortcutButton
                startIcon={<ArchiveOutlined />}
                label={constants.ARCHIVE_SECTION_NAME}
                count={collectionSummaries.get(ARCHIVE_SECTION)?.fileCount}
                onClick={openArchiveSection}
            />
        </>
    );
}
