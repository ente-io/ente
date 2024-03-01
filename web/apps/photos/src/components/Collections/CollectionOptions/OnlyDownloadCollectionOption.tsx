import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";

import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import { t } from "i18next";
import { CollectionActions } from ".";
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
    downloadOptionText?: string;
    isDownloadInProgress?: boolean;
}

export function OnlyDownloadCollectionOption({
    handleCollectionAction,
    downloadOptionText = t("DOWNLOAD"),
    isDownloadInProgress,
}: Iprops) {
    return (
        <OverflowMenuOption
            startIcon={
                !isDownloadInProgress ? (
                    <FileDownloadOutlinedIcon />
                ) : (
                    <EnteSpinner size="20px" sx={{ cursor: "not-allowed" }} />
                )
            }
            onClick={handleCollectionAction(CollectionActions.DOWNLOAD, false)}
        >
            {downloadOptionText}
        </OverflowMenuOption>
    );
}
