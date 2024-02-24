import { Box, Button, Link, Stack, Typography } from "@mui/material";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { Trans } from "react-i18next";

export const OPEN_STREET_MAP_LINK = "https://www.openstreetmap.org/";
export default function EnableMap({ onClose, enableMap, onRootClose }) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ENABLE_MAPS")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    {" "}
                    <Typography color="text.muted">
                        <Trans
                            i18nKey={"ENABLE_MAP_DESCRIPTION"}
                            components={{
                                a: (
                                    <Link
                                        target="_blank"
                                        href={OPEN_STREET_MAP_LINK}
                                    />
                                ),
                            }}
                        />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button color={"accent"} size="large" onClick={enableMap}>
                        {t("ENABLE")}
                    </Button>
                    <Button color={"secondary"} size="large" onClick={onClose}>
                        {t("CANCEL")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
