import { t } from "i18next";
import { useContext, useEffect, useState } from "react";

import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import CategoryIcon from "@mui/icons-material/Category";
import DeleteOutline from "@mui/icons-material/DeleteOutline";
import LockOutlined from "@mui/icons-material/LockOutlined";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import {
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    TRASH_SECTION,
} from "constants/collection";
import { GalleryContext } from "pages/gallery";
import { getUncategorizedCollection } from "services/collectionService";
import { CollectionSummaries } from "types/collection";
interface Iprops {
    closeSidebar: () => void;
    collectionSummaries: CollectionSummaries;
}

export default function ShortcutSection({
    closeSidebar,
    collectionSummaries,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);
    const [uncategorizedCollectionId, setUncategorizedCollectionID] =
        useState<number>();

    useEffect(() => {
        const main = async () => {
            const unCategorizedCollection = await getUncategorizedCollection();
            if (unCategorizedCollection) {
                setUncategorizedCollectionID(unCategorizedCollection.id);
            } else {
                setUncategorizedCollectionID(DUMMY_UNCATEGORIZED_COLLECTION);
            }
        };
        main();
    }, []);

    const openUncategorizedSection = () => {
        galleryContext.setActiveCollectionID(uncategorizedCollectionId);
        closeSidebar();
    };

    const openTrashSection = () => {
        galleryContext.setActiveCollectionID(TRASH_SECTION);
        closeSidebar();
    };

    const openArchiveSection = () => {
        galleryContext.setActiveCollectionID(ARCHIVE_SECTION);
        closeSidebar();
    };

    const openHiddenSection = () => {
        galleryContext.openHiddenSection(() => {
            closeSidebar();
        });
    };

    return (
        <>
            <EnteMenuItem
                startIcon={<CategoryIcon />}
                onClick={openUncategorizedSection}
                variant="captioned"
                label={t("UNCATEGORIZED")}
                subText={collectionSummaries
                    .get(uncategorizedCollectionId)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<ArchiveOutlined />}
                onClick={openArchiveSection}
                variant="captioned"
                label={t("ARCHIVE_SECTION_NAME")}
                subText={collectionSummaries
                    .get(ARCHIVE_SECTION)
                    ?.fileCount.toString()}
            />
            <EnteMenuItem
                startIcon={<VisibilityOff />}
                onClick={openHiddenSection}
                variant="captioned"
                label={t("HIDDEN")}
                subIcon={<LockOutlined />}
            />
            <EnteMenuItem
                startIcon={<DeleteOutline />}
                onClick={openTrashSection}
                variant="captioned"
                label={t("TRASH")}
                subText={collectionSummaries
                    .get(TRASH_SECTION)
                    ?.fileCount.toString()}
            />
        </>
    );
}
