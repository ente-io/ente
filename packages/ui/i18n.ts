import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import Backend from "i18next-http-backend";
import { isDevBuild } from "@/utils/env";
import { getUserLocales } from "get-user-locale";
import { includes } from "@/utils/type-guards";

/**
 * List of all {@link SupportedLocale}s.
 *
 * Locales are combinations of a language code, and an optional region code.
 *
 * For example, "en", "en-US", "en-IN" (Indian English), "pt" (Portuguese),
 * "pt-BR" (Brazilian Portuguese).
 *
 * In our Crowdin Project, we have work-in-progress translations into more
 * languages than this. When a translation reaches a high enough coverage, say
 * 90%, then we manually add it to this list of supported languages.
 */
export const supportedLocales = ["en", "fr", "zh", "nl", "es"] as const;
/** The type of  {@link supportedLocale}s. */
export type SupportedLocale = (typeof supportedLocales)[number];

/**
 * Load translations.
 *
 * Localization and related concerns (aka "internationalization", or "i18n") for
 * our apps is handled by i18n framework.
 *
 * In addition to the base i18next package, we use two of its plugins:
 *
 * - i18next-http-backend, for loading the JSON files containin the translations
 *   at runtime, and
 *
 * - react-i18next, which adds React specific APIs
 */
export const setupI18n = async (savedLocaleString?: string) => {
    const locale = closestSupportedLocale(savedLocaleString);

    // https://www.i18next.com/overview/api
    await i18n
        // i18next-http-backend: Asynchronously loads translations over HTTP
        // https://github.com/i18next/i18next-http-backend
        .use(Backend)
        // react-i18next: React support
        // Pass the i18n instance to react-i18next.
        .use(initReactI18next)
        // Initialize i18next
        // Option docs: https://www.i18next.com/overview/configuration-options
        .init({
            debug: isDevBuild,
            returnEmptyString: false,
            fallbackLng: "en",
            // i18next calls it language, but it really is the locale
            lng: locale,
            interpolation: {
                escapeValue: false, // not needed for react as it escapes by default
            },
            react: {
                useSuspense: false,
                transKeepBasicHtmlNodesFor: [
                    "div",
                    "strong",
                    "h2",
                    "span",
                    "code",
                    "p",
                    "br",
                ],
            },
            load: "languageOnly",
        });

    i18n.services.formatter?.add("dateTime", (value, lng) => {
        return new Date(value / 1000).toLocaleDateString(lng, {
            year: "numeric",
            month: "long",
            day: "numeric",
        });
    });
};

/**
 * Return the current locale in which our user interface is being shown.
 *
 * Note that this may be different from the user's locale. For example, the
 * browser might be set to en-GB, but since we don't support that specific
 * variant of English, this value will be (say) en-US.
 */
export const currentLocale = () => {
    const locale = i18n.resolvedLanguage;
    return locale && includes(supportedLocales, locale) ? locale : "en";
};

/**
 * Return the closest / best matching {@link SupportedLocale}.
 *
 * It takes as input a {@link savedLocaleString}, which denotes the user's
 * explicitly chosen preference (which we then persist in local storage).
 * Subsequently, we use this to (usually literally) return the supported locale
 * that it represents.
 *
 * If {@link savedLocaleString} is `undefined`, it tries to deduce the closest
 * {@link SupportedLocale} that matches the browser's locale.
 */
export function closestSupportedLocale(
    savedLocaleString?: string,
): SupportedLocale {
    const ss = savedLocaleString;
    if (ss && includes(supportedLocales, ss)) return ss;

    /*
    switch (savedLocaleString) {
        case "en":
            return Language.en;
        case "fr":
            return Language.fr;
        case "zh":
            return Language.zh;
        case "nl":
            return Language.nl;
        case "es":
            return Language.es;
    }
    */

    for (const us of getUserLocales()) {
        // Exact match
        if (us && includes(supportedLocales, us)) return us;

        // Language match
        if (us.startsWith("en")) {
            return "en";
        } else if (us.startsWith("fr")) {
            return "fr";
        } else if (us.startsWith("zh")) {
            return "zh";
        } else if (us.startsWith("nl")) {
            return "nl";
        } else if (us.startsWith("es")) {
            return "es";
        }
    }

    // Fallback
    return "en";
}
