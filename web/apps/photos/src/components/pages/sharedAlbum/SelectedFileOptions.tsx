import { FluidContainer } from "@ente/shared/components/Container";
import { SelectionBar } from "@ente/shared/components/Navbar/SelectionBar";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import { Box, IconButton, Stack, Tooltip } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import { formatNumber } from "utils/number/format";

interface Props {
    count: number;
    clearSelection: () => void;
    downloadFilesHelper: () => void;
}

const SelectedFileOptions = ({
    downloadFilesHelper,
    count,
    clearSelection,
}: Props) => {
    const { isMobile } = useContext(AppContext);

    return (
        <SelectionBar isMobile={isMobile}>
            <FluidContainer>
                <IconButton onClick={clearSelection}>
                    <CloseIcon />
                </IconButton>
                <Box ml={1.5}>
                    {formatNumber(count)} {t("SELECTED")}{" "}
                </Box>
            </FluidContainer>
            <Stack spacing={2} direction="row" mr={2}>
                <Tooltip title={t("DOWNLOAD")}>
                    <IconButton onClick={downloadFilesHelper}>
                        <DownloadIcon />
                    </IconButton>
                </Tooltip>
            </Stack>
        </SelectionBar>
    );
};

export default SelectedFileOptions;
