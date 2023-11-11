import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import Backend from 'i18next-http-backend';
import { getBestPossibleUserLocale } from './utils';

export const setupI18n = async () => {
    await i18n
        // i18next-http-backend
        // loads translations from your server
        // https://github.com/i18next/i18next-http-backend,
        .use(Backend)
        // pass the i18n instance to react-i18next.
        .use(initReactI18next)
        // init i18next
        // for all options read: https://www.i18next.com/overview/configuration-options
        .init({
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
