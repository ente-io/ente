import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import ArchiveOutlined from "@mui/icons-material/ArchiveOutlined";
import LogoutIcon from "@mui/icons-material/Logout";
import Unarchive from "@mui/icons-material/Unarchive";
import { t } from "i18next";
import { CollectionActions } from ".";

interface Iprops {
    isArchived: boolean;
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
}

export function SharedCollectionOption({
    isArchived,
    handleCollectionAction,
}: Iprops) {
    return (
        <>
            {isArchived ? (
                <OverflowMenuOption
                    onClick={handleCollectionAction(
                        CollectionActions.UNARCHIVE,
                    )}
                    startIcon={<Unarchive />}
                >
                    {t("UNARCHIVE_COLLECTION")}
                </OverflowMenuOption>
            ) : (
                <OverflowMenuOption
                    onClick={handleCollectionAction(CollectionActions.ARCHIVE)}
                    startIcon={<ArchiveOutlined />}
                >
                    {t("ARCHIVE_COLLECTION")}
                </OverflowMenuOption>
            )}
            <OverflowMenuOption
                startIcon={<LogoutIcon />}
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_LEAVE_SHARED_ALBUM,
                    false,
                )}
            >
                {t("LEAVE_ALBUM")}
            </OverflowMenuOption>
        </>
    );
}
