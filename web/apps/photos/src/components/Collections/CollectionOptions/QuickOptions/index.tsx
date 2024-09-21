import { FlexWrapper } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import PeopleIcon from "@mui/icons-material/People";
import { IconButton, Tooltip } from "@mui/material";
import { t } from "i18next";
import { CollectionSummaryType } from "types/collection";
import { CollectionActions } from "..";
import { DownloadQuickOption } from "./DownloadQuickOption";
import { EmptyTrashQuickOption } from "./EmptyTrashQuickOption";

interface QuickOptionsProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
    isDownloadInProgress: boolean;
}

export const QuickOptions: React.FC<QuickOptionsProps> = ({
    handleCollectionAction,
    collectionSummaryType,
    isDownloadInProgress,
}) => {
    return (
        <FlexWrapper sx={{ gap: "16px" }}>
            {showEmptyTrashQuickOption(collectionSummaryType) && (
                <EmptyTrashQuickOption
                    handleCollectionAction={handleCollectionAction}
                />
            )}
            {showDownloadQuickOption(collectionSummaryType) &&
                (!isDownloadInProgress ? (
                    <DownloadQuickOption
                        handleCollectionAction={handleCollectionAction}
                        collectionSummaryType={collectionSummaryType}
                    />
                ) : (
                    <EnteSpinner size="20px" sx={{ cursor: "not-allowed" }} />
                ))}
            {showShareQuickOption(collectionSummaryType) && (
                <ShareQuickOption
                    handleCollectionAction={handleCollectionAction}
                    collectionSummaryType={collectionSummaryType}
                />
            )}
        </FlexWrapper>
    );
};

const showEmptyTrashQuickOption = (type: CollectionSummaryType) => {
    return type === CollectionSummaryType.trash;
};

const showDownloadQuickOption = (type: CollectionSummaryType) => {
    return (
        type === CollectionSummaryType.folder ||
        type === CollectionSummaryType.favorites ||
        type === CollectionSummaryType.album ||
        type === CollectionSummaryType.uncategorized ||
        type === CollectionSummaryType.hiddenItems ||
        type === CollectionSummaryType.incomingShareViewer ||
        type === CollectionSummaryType.incomingShareCollaborator ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived ||
        type === CollectionSummaryType.pinned
    );
};

const showShareQuickOption = (type: CollectionSummaryType) => {
    return (
        type === CollectionSummaryType.folder ||
        type === CollectionSummaryType.album ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived ||
        type === CollectionSummaryType.incomingShareViewer ||
        type === CollectionSummaryType.incomingShareCollaborator ||
        type === CollectionSummaryType.pinned
    );
};

interface ShareQuickOptionProps {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

const ShareQuickOption: React.FC<ShareQuickOptionProps> = ({
    handleCollectionAction,
    collectionSummaryType,
}) => (
    <Tooltip
        title={
            collectionSummaryType ===
                CollectionSummaryType.incomingShareViewer ||
            collectionSummaryType ===
                CollectionSummaryType.incomingShareCollaborator
                ? t("SHARING_DETAILS")
                : collectionSummaryType ===
                        CollectionSummaryType.outgoingShare ||
                    collectionSummaryType ===
                        CollectionSummaryType.sharedOnlyViaLink
                  ? t("MODIFY_SHARING")
                  : t("SHARE_COLLECTION")
        }
    >
        <IconButton
            onClick={handleCollectionAction(
                CollectionActions.SHOW_SHARE_DIALOG,
                false,
            )}
        >
            <PeopleIcon />
        </IconButton>
    </Tooltip>
);
