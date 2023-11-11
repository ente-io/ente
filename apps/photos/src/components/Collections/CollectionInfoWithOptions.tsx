import { CollectionInfo } from './CollectionInfo';
import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import CollectionOptions from 'components/Collections/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { SpaceBetweenFlex } from '@ente/shared/components/Container';
import { CollectionInfoBarWrapper } from './styledComponents';
import { shouldShowOptions } from 'utils/collection';
import { CollectionSummaryType } from 'constants/collection';
import Favorite from '@mui/icons-material/FavoriteRounded';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import PeopleIcon from '@mui/icons-material/People';
import LinkIcon from '@mui/icons-material/Link';
import { SetCollectionDownloadProgressAttributes } from 'types/gallery';

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    setCollectionDownloadProgressAttributesCreator: (
        collectionID: number
    ) => SetCollectionDownloadProgressAttributes;
    isActiveCollectionDownloadInProgress: () => boolean;
    setActiveCollectionID: (collectionID: number) => void;
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
            case CollectionSummaryType.favorites:
                return <Favorite />;
            case CollectionSummaryType.archived:
                return <ArchiveOutlined />;
            case CollectionSummaryType.incomingShareViewer:
            case CollectionSummaryType.incomingShareCollaborator:
                return <PeopleIcon />;
            case CollectionSummaryType.outgoingShare:
                return <PeopleIcon />;
            case CollectionSummaryType.sharedOnlyViaLink:
                return <LinkIcon />;
            default:
                return <></>;
        }
    };
    return (
        <CollectionInfoBarWrapper>
            <SpaceBetweenFlex>
                <CollectionInfo
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
        </CollectionInfoBarWrapper>
    );
}
