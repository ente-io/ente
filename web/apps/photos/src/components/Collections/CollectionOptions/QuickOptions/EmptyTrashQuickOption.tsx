import DeleteOutlinedIcon from "@mui/icons-material/DeleteOutlined";
import { IconButton, Tooltip } from "@mui/material";
import { t } from "i18next";
import { CollectionActions } from "..";

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean,
    ) => (...args: any[]) => Promise<void>;
}

export function EmptyTrashQuickOption({ handleCollectionAction }: Iprops) {
    return (
        <Tooltip title={t("EMPTY_TRASH")}>
            <IconButton
                onClick={handleCollectionAction(
                    CollectionActions.CONFIRM_EMPTY_TRASH,
                    false,
                )}
            >
                <DeleteOutlinedIcon />
            </IconButton>
        </Tooltip>
    );
}
