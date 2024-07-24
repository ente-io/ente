import { SelectionBar } from "@/base/components/Navbar";
import { FluidContainer } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import DownloadIcon from "@mui/icons-material/Download";
import { Box, IconButton, Stack, Tooltip } from "@mui/material";
import { t } from "i18next";
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
    return (
        <SelectionBar>
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
