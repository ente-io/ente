import { FluidContainer } from "@ente/shared/components/Container";
import { SelectionBar } from "@ente/shared/components/Navbar/SelectionBar";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import { Box, IconButton, Tooltip } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import { formatNumber } from "utils/number/format";
import { getTrashFilesMessage } from "utils/ui";

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
    const { setDialogMessage, isMobile } = useContext(AppContext);

    const trashHandler = () =>
        setDialogMessage(getTrashFilesMessage(deleteFileHelper));

    return (
        <SelectionBar isMobile={isMobile}>
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
                <Box ml={1.5}>
                    {formatNumber(count)} {t("SELECTED")}
                </Box>
            </FluidContainer>
            <Tooltip title={t("DELETE")}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </Tooltip>
        </SelectionBar>
    );
}
