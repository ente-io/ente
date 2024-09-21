import type { Collection } from "@/media/collection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "@/new/photos/components/Gallery/ListHeader";
import type {
    CollectionSummary,
    CollectionSummaryType,
} from "@/new/photos/types/collection";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import Favorite from "@mui/icons-material/FavoriteRounded";
import LinkIcon from "@mui/icons-material/Link";
import PeopleIcon from "@mui/icons-material/People";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import CollectionOptions from "components/Collections/CollectionOptions";
import type { Dispatch, SetStateAction } from "react";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
    isActiveCollectionDownloadInProgress: () => boolean;
    setActiveCollectionID: (collectionID: number) => void;
    setShowAlbumCastDialog: Dispatch<SetStateAction<boolean>>;
}

export default function CollectionInfoWithOptions({
    collectionSummary,
    ...props
}: Iprops) {
    if (!collectionSummary) {
        return <></>;
    }

    const { name, type, fileCount } = collectionSummary;

    const EndIcon = ({ type }: { type: CollectionSummaryType }) => {
        switch (type) {
            case "favorites":
                return <Favorite />;
            case "archived":
                return <ArchiveOutlined />;
            case "incomingShareViewer":
            case "incomingShareCollaborator":
                return <PeopleIcon />;
            case "outgoingShare":
                return <PeopleIcon />;
            case "sharedOnlyViaLink":
                return <LinkIcon />;
            default:
                return <></>;
        }
    };

    return (
        <GalleryItemsHeaderAdapter>
            <SpaceBetweenFlex>
                <GalleryItemsSummary
                    name={name}
                    fileCount={fileCount}
                    endIcon={<EndIcon type={type} />}
                />
                {shouldShowOptions(type) && (
                    <CollectionOptions
                        {...props}
                        collectionSummaryType={type}
                    />
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
}

const shouldShowOptions = (type: CollectionSummaryType) =>
    type != "all" && type != "archive";
