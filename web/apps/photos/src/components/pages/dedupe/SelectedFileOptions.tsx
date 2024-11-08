import { SelectionBar } from "@/base/components/Navbar";
import { AppContext } from "@/new/photos/types/context";
import { FluidContainer } from "@ente/shared/components/Container";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import { Box, IconButton, Tooltip } from "@mui/material";
import { t } from "i18next";
import { useContext } from "react";

interface IProps {
    deleteFileHelper: () => void;
    close: () => void;
    count: number;
    clearSelection: () => void;
}

export default function DeduplicateOptions({
    deleteFileHelper,
    close,
    count,
    clearSelection,
}: IProps) {
    const { showMiniDialog } = useContext(AppContext);

    const trashHandler = () =>
        showMiniDialog({
            title: t("trash_files_title"),
            message: t("TRASH_FILES_MESSAGE"),
            continue: {
                text: t("MOVE_TO_TRASH"),
                color: "critical",
                action: deleteFileHelper,
            },
        });

    return (
        <SelectionBar>
            <FluidContainer>
                {count ? (
                    <IconButton onClick={clearSelection}>
                        <CloseIcon />
                    </IconButton>
                ) : (
                    <IconButton onClick={close}>
                        <BackButton />
                    </IconButton>
                )}
                <Box ml={1.5}>{t("selected_count", { selected: count })}</Box>
            </FluidContainer>
            <Tooltip title={t("delete")}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </Tooltip>
        </SelectionBar>
    );
}
