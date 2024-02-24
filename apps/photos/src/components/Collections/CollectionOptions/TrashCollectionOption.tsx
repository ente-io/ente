import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";

import DeleteOutlinedIcon from "@mui/icons-material/DeleteOutlined";
import { t } from "i18next";
import { CollectionActions } from ".";

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
}

export function TrashCollectionOption({ handleCollectionAction }: Iprops) {
    return (
        <OverflowMenuOption
            color="critical"
            startIcon={<DeleteOutlinedIcon />}
            onClick={handleCollectionAction(
                CollectionActions.CONFIRM_EMPTY_TRASH,
                false,
            )}
        >
            {t("EMPTY_TRASH")}
        </OverflowMenuOption>
    );
}
