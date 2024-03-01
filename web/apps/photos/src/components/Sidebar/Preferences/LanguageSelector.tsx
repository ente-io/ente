import {
    getLocaleInUse,
    setLocaleInUse,
    supportedLocales,
    type SupportedLocale,
} from "@/ui/i18n";
import DropdownInput, { DropdownOption } from "components/DropdownInput";
import { t } from "i18next";
import { useRouter } from "next/router";

/**
 * Human readable name for each supported locale
 *
 * TODO (MR): This names themselves should be localized.
 */
export const localeName = (locale: SupportedLocale) => {
    switch (locale) {
        case "en-US":
            return "English";
        case "fr-FR":
            return "Français";
        case "zh-CN":
            return "中文";
        case "nl-NL":
            return "Nederlands";
        case "es-ES":
            return "Español";
        case "pt-BR":
            return "Brazilian Portuguese";
    }
};

const getLanguageOptions = (): DropdownOption<SupportedLocale>[] => {
    return supportedLocales.map((locale) => ({
        label: localeName(locale),
        value: locale,
    }));
};

export const LanguageSelector = () => {
    const locale = getLocaleInUse();
    // Enhancement: Is this full reload needed?
    const router = useRouter();

    const updateCurrentLocale = (newLocale: SupportedLocale) => {
        setLocaleInUse(newLocale);
        router.reload();
    };

    return (
        <DropdownInput
            options={getLanguageOptions()}
            label={t("LANGUAGE")}
            labelProps={{ color: "text.muted" }}
            selected={locale}
            setSelected={updateCurrentLocale}
        />
    );
};
