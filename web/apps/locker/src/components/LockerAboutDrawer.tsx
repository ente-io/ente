import OpenInNewOutlinedIcon from "@mui/icons-material/OpenInNewOutlined";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
} from "ente-base/components/RowButton";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { t } from "i18next";
import React from "react";

const openExternal = (url: string) => window.open(url, "_blank", "noopener");

export const LockerAboutDrawer: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("about")}
        >
            <RowButtonGroup sx={{ mx: 2, my: 2 }}>
                <RowButton
                    label={t("we_are_open_source")}
                    endIcon={<OpenInNewOutlinedIcon />}
                    onClick={() => openExternal("https://github.com/ente-io/ente")}
                />
                <RowButtonDivider />
                <RowButton
                    label={t("privacy")}
                    endIcon={<OpenInNewOutlinedIcon />}
                    onClick={() => openExternal("https://ente.io/privacy")}
                />
                <RowButtonDivider />
                <RowButton
                    label={t("terms")}
                    endIcon={<OpenInNewOutlinedIcon />}
                    onClick={() => openExternal("https://ente.io/terms")}
                />
            </RowButtonGroup>
        </TitledNestedSidebarDrawer>
    );
};
