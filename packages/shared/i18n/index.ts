import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import Backend from 'i18next-http-backend';
import { getBestPossibleUserLocale } from './utils';
import { isDevBuild } from '../network/api';

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
            fallbackLng: 'en',
            lng: getBestPossibleUserLocale(),
            interpolation: {
                escapeValue: false, // not needed for react as it escapes by default
            },
            react: {
                useSuspense: false,
                transKeepBasicHtmlNodesFor: [
                    'div',
                    'strong',
                    'h2',
                    'span',
                    'code',
                    'p',
                    'br',
                ],
            },
            load: 'languageOnly',
        });

    i18n.services.formatter.add('dateTime', (value, lng) => {
        return new Date(value / 1000).toLocaleDateString(lng, {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
        });
    });
};
