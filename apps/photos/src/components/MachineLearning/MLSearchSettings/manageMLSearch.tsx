import { Box, Stack } from "@mui/material";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import Titlebar from "components/Titlebar";
import { t } from "i18next";

export default function ManageMLSearch({
    onClose,
    disableMlSearch,
    handleDisableFaceSearch,
    onRootClose,
}) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ML_SEARCH")}
                onRootClose={onRootClose}
            />
            <Box px={"16px"}>
                <Stack py={"20px"} spacing={"24px"}>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={disableMlSearch}
                            label={t("DISABLE_BETA")}
                        />
                    </MenuItemGroup>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={handleDisableFaceSearch}
                            label={t("DISABLE_FACE_SEARCH")}
                        />
                    </MenuItemGroup>
                </Stack>
            </Box>
        </Stack>
    );
}
