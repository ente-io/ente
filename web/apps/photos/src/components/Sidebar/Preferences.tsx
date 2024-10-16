import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import {
    useModalVisibility,
    type NestedDrawerVisibilityProps,
} from "@/base/components/utils/modal";
import {
    getLocaleInUse,
    setLocaleInUse,
    supportedLocales,
    type SupportedLocale,
} from "@/base/i18n";
import { MLSettings } from "@/new/photos/components/MLSettings";
import { isMLSupported } from "@/new/photos/services/ml";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import ChevronRight from "@mui/icons-material/ChevronRight";
import ScienceIcon from "@mui/icons-material/Science";
import { Box, DialogProps, Stack } from "@mui/material";
import DropdownInput from "components/DropdownInput";
import { t } from "i18next";
import React from "react";
import { AdvancedSettings } from "./AdvancedSettings";
import { MapSettings } from "./MapSetting";

export const Preferences: React.FC<NestedDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const { show: showMapSettings, props: mapSettingsVisibilityProps } =
        useModalVisibility();
    const {
        show: showAdvancedSettings,
        props: advancedSettingsVisibilityProps,
    } = useModalVisibility();
    const { show: showMLSettings, props: mlSettingsVisibilityProps } =
        useModalVisibility();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };

    return (
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={handleDrawerClose}
            BackdropProps={{
                sx: { "&&&": { backgroundColor: "transparent" } },
            }}
        >
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("preferences")}
                    onRootClose={handleRootClose}
                />
                <Box px={"8px"}>
                    <Stack py="20px" spacing="24px">
                        <LanguageSelector />
                        <EnteMenuItem
                            onClick={showMapSettings}
                            endIcon={<ChevronRight />}
                            label={t("map")}
                        />
                        <EnteMenuItem
                            onClick={showAdvancedSettings}
                            endIcon={<ChevronRight />}
                            label={t("advanced")}
                        />
                        {isMLSupported && (
                            <Box>
                                <MenuSectionTitle
                                    title={t("labs")}
                                    icon={<ScienceIcon />}
                                />
                                <MenuItemGroup>
                                    <EnteMenuItem
                                        endIcon={<ChevronRight />}
                                        onClick={showMLSettings}
                                        label={t("ml_search")}
                                    />
                                </MenuItemGroup>
                            </Box>
                        )}
                    </Stack>
                </Box>
            </Stack>
            <MapSettings
                {...mapSettingsVisibilityProps}
                onRootClose={onRootClose}
            />
            <AdvancedSettings
                {...advancedSettingsVisibilityProps}
                onRootClose={onRootClose}
            />
            <MLSettings
                {...mlSettingsVisibilityProps}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
};

const LanguageSelector = () => {
    const locale = getLocaleInUse();

    const updateCurrentLocale = (newLocale: SupportedLocale) => {
        setLocaleInUse(newLocale);
        // A full reload is needed because we use the global `t` instance
        // instead of the useTranslation hook.
        window.location.reload();
    };

    const options = supportedLocales.map((locale) => ({
        label: localeName(locale),
        value: locale,
    }));

    return (
        <DropdownInput
            options={options}
            label={t("language")}
            labelProps={{ color: "text.muted" }}
            selected={locale}
            setSelected={updateCurrentLocale}
        />
    );
};

/**
 * Human readable name for each supported locale.
 */
const localeName = (locale: SupportedLocale) => {
    switch (locale) {
        case "en-US":
            return "English";
        case "fr-FR":
            return "Français";
        case "de-DE":
            return "Deutsch";
        case "zh-CN":
            return "中文";
        case "nl-NL":
            return "Nederlands";
        case "es-ES":
            return "Español";
        case "pt-BR":
            return "Português Brasileiro";
        case "ru-RU":
            return "Русский";
        case "pl-PL":
            return "Polski";
        case "it-IT":
            return "Italiano";
        case "lt-LT":
            return "Lietuvių kalba";
    }
};
