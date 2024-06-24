import { isDevBuild } from "@/next/env";
import log from "@/next/log";
import { includes } from "@/utils/type-guards";
import { getUserLocales } from "get-user-locale";
import i18n from "i18next";
import resourcesToBackend from "i18next-resources-to-backend";
import { initReactI18next } from "react-i18next";
import { object, string } from "yup";

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
    "de-DE" /* German */,
    "zh-CN" /* Simplified Chinese */,
    "nl-NL" /* Dutch */,
    "es-ES" /* Spanish */,
    "pt-BR" /* Portuguese, Brazilian */,
    "ru-RU" /* Russian */,
] as const;

/** The type of {@link supportedLocales}. */
export type SupportedLocale = (typeof supportedLocales)[number];

const defaultLocale: SupportedLocale = "en-US";

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
export const setupI18n = async () => {
    const localeString = savedLocaleStringMigratingIfNeeded();
    const locale = closestSupportedLocale(localeString);

    // https://www.i18next.com/overview/api
    await i18n
        // i18next-resources-to-backend: Use webpack to bundle translation, but
        // still fetch them lazily using a dynamic import.
        //
        // The benefit of this is that, unlike the http backend that uses files
        // from the public folder, these JSON files are content hash named and
        // eminently cacheable.
        //
        // https://github.com/i18next/i18next-resources-to-backend
        .use(
            resourcesToBackend(
                (language: string, namespace: string) =>
                    import(`./locales/${language}/${namespace}.json`),
            ),
        )
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
            fallbackLng: defaultLocale,
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
 * Read and return the locale (if any) that we'd previously saved in local
 * storage.
 *
 * If it finds a locale stored in the old format, it also updates the saved
 * value and returns it in the new format.
 */
const savedLocaleStringMigratingIfNeeded = (): SupportedLocale | undefined => {
    const ls = localStorage.getItem("locale");

    // An older version of our code had stored only the language code, not the
    // full locale. Migrate these to the new locale format. Luckily, all such
    // languages can be unambiguously mapped to locales in our current set.
    //
    // This migration is dated Feb 2024. And it can be removed after a few
    // months, because by then either customers would've opened the app and
    // their setting migrated to the new format, or the browser would've cleared
    // the older local storage entry anyway.

    if (!ls) {
        // Nothing found
        return undefined;
    }

    if (includes(supportedLocales, ls)) {
        // Already in the new format
        return ls;
    }

    let value: string | undefined;
    try {
        const oldFormatData = object({ value: string() }).json().cast(ls);
        value = oldFormatData.value;
    } catch (e) {
        // Not a valid JSON, or not in the format we expected it. This shouldn't
        // have happened, we're the only one setting it.
        log.error("Failed to parse locale obtained from local storage", e);
        // Also remove the old key, it is not parseable by us anymore.
        localStorage.removeItem("locale");
        return undefined;
    }

    const newValue = mapOldValue(value);
    if (newValue) localStorage.setItem("locale", newValue);

    return newValue;
};

const mapOldValue = (value: string | undefined) => {
    switch (value) {
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
        default:
            return undefined;
    }
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
const closestSupportedLocale = (
    savedLocaleString?: string,
): SupportedLocale => {
    const ss = savedLocaleString;
    if (ss && includes(supportedLocales, ss)) return ss;

    for (const ls of getUserLocales()) {
        // Exact match
        if (ls && includes(supportedLocales, ls)) return ls;

        // Language match
        if (ls.startsWith("en")) {
            return "en-US";
        } else if (ls.startsWith("fr")) {
            return "fr-FR";
        } else if (ls.startsWith("de")) {
            return "de-DE";
        } else if (ls.startsWith("zh")) {
            return "zh-CN";
        } else if (ls.startsWith("nl")) {
            return "nl-NL";
        } else if (ls.startsWith("es")) {
            return "es-ES";
        } else if (ls.startsWith("pt-BR")) {
            // We'll never get here (it'd already be an exact match), just kept
            // to keep this list consistent.
            return "pt-BR";
        } else if (ls.startsWith("ru")) {
            return "ru-RU";
        }
    }

    // Fallback
    return defaultLocale;
};

/**
 * Return the locale that is currently being used to show the app's UI.
 *
 * Note that this may be different from the user's locale. For example, the
 * browser might be set to en-GB, but since we don't support that specific
 * variant of English, this value will be (say) en-US.
 */
export const getLocaleInUse = (): SupportedLocale => {
    const locale = i18n.resolvedLanguage;
    if (locale && includes(supportedLocales, locale)) {
        return locale;
    } else {
        // This shouldn't have happened. Log an error to attract attention.
        log.error(
            `Expected the i18next locale to be one of the supported values, but instead found ${locale}`,
        );
        return defaultLocale;
    }
};

/**
 * Set the locale that should be used to show the app's UI.
 *
 * This updates both the i18next state, and also the corresponding user
 * preference that is stored in local storage.
 */
export const setLocaleInUse = async (locale: SupportedLocale) => {
    localStorage.setItem("locale", locale);
    return i18n.changeLanguage(locale);
};

/**
 * A no-op marker for strings that, for various reasons, are not translated.
 *
 * This function does nothing, it just returns back the passed it string
 * verbatim. It is only kept as a way for us to keep track of strings that are
 * not translated (and for some reason, are currently not meant to be), but
 * still are user visible.
 *
 * It is the sibling of the {@link t} function provided by i18next.
 */
export const ut = (s: string) => s;
