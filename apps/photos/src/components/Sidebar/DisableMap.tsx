import { Box, Button, Stack, Typography } from "@mui/material";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { Trans } from "react-i18next";

export default function EnableMap({ onClose, disableMap, onRootClose }) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("DISABLE_MAPS")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    <Typography color="text.muted">
                        <Trans i18nKey={"DISABLE_MAP_DESCRIPTION"} />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button
                        color={"critical"}
                        size="large"
                        onClick={disableMap}
                    >
                        {t("DISABLE")}
                    </Button>
                    <Button color={"secondary"} size="large" onClick={onClose}>
                        {t("CANCEL")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
