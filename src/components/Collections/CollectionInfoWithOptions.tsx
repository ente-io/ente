import { CollectionInfo } from './CollectionInfo';
import React from 'react';
import { Collection, CollectionSummary } from 'types/collection';
import CollectionOptions from 'components/Collections/CollectionOptions';
import { SetCollectionNamerAttributes } from 'components/Collections/CollectionNamer';
import { SpaceBetweenFlex } from 'components/Container';
import { CollectionInfoBarWrapper } from './styledComponents';
import { shouldShowOptions } from 'utils/collection';
import { CollectionSummaryType } from 'constants/collection';
import Favorite from '@mui/icons-material/FavoriteRounded';
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import PeopleIcon from '@mui/icons-material/People';
import LinkIcon from '@mui/icons-material/Link';

interface Iprops {
    activeCollection: Collection;
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
}

interface Iprops {
    collectionSummary: CollectionSummary;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    activeCollection: Collection;
    activeCollectionID: number;
    showCollectionShareModal: () => void;
    redirectToAll: () => void;
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
            case CollectionSummaryType.incomingShare:
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
