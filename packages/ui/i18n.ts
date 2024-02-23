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
export const supportedLocales = [
    "en-US" /* English */,
    "fr-FR" /* French */,
    "zh-CN" /* Simplified Chinese */,
    "nl-NL" /* Dutch */,
    "es-ES" /* Spanish */,
] as const;

/** The type of {@link supportedLocale}s. */
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
            // i18next calls it language, but it really is the locale
            lng: locale,
            // Tell i18next about the locales we support
            supportedLngs: supportedLocales,
            // Ask it to fetch only exact matches
            //
            // By default, if the lng was set to, say, en-GB, i18n would make
            // network requests for ["en-GB", "en", "dev"] (where dev is the
            // default fallback). By setting `load` to "currentOnly", we ask
            // i18next to only try and fetch "en-GB" (i.e. the exact match).
            load: "currentOnly",
            // Disallow empty strings as valid translations.
            //
            // This way, empty strings will fallback to `fallbackLng`
            returnEmptyString: false,
            // The language to use if translation for a particular key in the
            // current `lng` is not available.
            fallbackLng: "en-US",
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

    // An older version of our code had stored only the language code, not the
    // full locale. Map these to the default region we'd started off with.
    switch (savedLocaleString) {
        case "en":
            return "en-US";
        case "fr":
            return "fr-FR";
        case "zh":
            return "zh-CN";
        case "nl":
            return "nl-NL";
        case "es":
            return "es-ES";
    }

    for (const us of getUserLocales()) {
        // Exact match
        if (us && includes(supportedLocales, us)) return us;

        // Language match
        if (us.startsWith("en")) {
            return "en-US";
        } else if (us.startsWith("fr")) {
            return "fr-FR";
        } else if (us.startsWith("zh")) {
            return "zh-CN";
        } else if (us.startsWith("nl")) {
            return "nl-NL";
        } else if (us.startsWith("es")) {
            return "es-ES";
        }
    }

    // Fallback
    return "en-US";
}
