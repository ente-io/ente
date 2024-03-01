import { ML_BLOG_LINK } from "@ente/shared/constants/urls";
import { Box, Button, Stack, Typography } from "@mui/material";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { openLink } from "utils/common";

export default function EnableMLSearch({
    onClose,
    enableMlSearch,
    onRootClose,
}) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ML_SEARCH")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    {" "}
                    <Typography color="text.muted">
                        <Trans i18nKey={"ENABLE_ML_SEARCH_DESCRIPTION"} />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button
                        color={"accent"}
                        size="large"
                        onClick={enableMlSearch}
                    >
                        {t("ENABLE")}
                    </Button>
                    <Button
                        color={"secondary"}
                        size="large"
                        onClick={() => openLink(ML_BLOG_LINK, true)}
                    >
                        {t("ML_MORE_DETAILS")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
