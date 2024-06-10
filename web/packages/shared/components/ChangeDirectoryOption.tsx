import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import FolderIcon from "@mui/icons-material/Folder";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { t } from "i18next";

interface ChangeDirectoryOptionProps {
    onClick: () => void;
}

export default function ChangeDirectoryOption({
    onClick,
}: ChangeDirectoryOptionProps) {
    return (
        <OverflowMenu
            triggerButtonProps={{
                sx: {
                    ml: 1,
                },
            }}
            ariaControls={"export-option"}
            triggerButtonIcon={<MoreHoriz />}
        >
            <OverflowMenuOption onClick={onClick} startIcon={<FolderIcon />}>
                {t("CHANGE_FOLDER")}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
