import { FlexWrapper } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { CollectionSummaryType } from "constants/collection";
import {
    showDownloadQuickOption,
    showEmptyTrashQuickOption,
    showShareQuickOption,
} from "utils/collection";
import { CollectionActions } from "..";
import { DownloadQuickOption } from "./DownloadQuickOption";
import { EmptyTrashQuickOption } from "./EmptyTrashQuickOption";
import { ShareQuickOption } from "./ShareQuickOption";
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
    isDownloadInProgress: boolean;
}

export function QuickOptions({
    handleCollectionAction,
    collectionSummaryType,
    isDownloadInProgress,
}: Iprops) {
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
}
