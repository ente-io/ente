import PeopleIcon from "@mui/icons-material/People";
import { IconButton, Tooltip } from "@mui/material";
import { CollectionSummaryType } from "constants/collection";
import { t } from "i18next";
import { CollectionActions } from "..";

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
    collectionSummaryType: CollectionSummaryType;
}

export function ShareQuickOption({
    handleCollectionAction,
    collectionSummaryType,
}: Iprops) {
    return (
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
}
