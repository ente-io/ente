import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { t } from "i18next";

/**
 * Create attributes for a {@link MiniDialog} notifying the user that some of
 * the files were not processed because they belonged to other users.
 */
export const notifyOthersFilesDialogAttributes = () => ({
    title: t("note"),
    icon: <InfoOutlinedIcon />,
    message: t("unowned_files_not_processed"),
    cancel: t("ok"),
});
