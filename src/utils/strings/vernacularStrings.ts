import englishConstants from './englishConstants';

/** Enums of supported locale */
export enum locale {
    en = 'en',
    hi = 'hi',
}

/**
 * Defines a template with placeholders which can then be
 * substituted at run time. Enabling the developer to create
 * different template for different locale and populate them
 * at run time.
 *
 * @param strings
 * @param keys
 */
export function template(strings: TemplateStringsArray, ...keys: string[]) {
    return (...values: any[]) => {
        const dict = values[values.length - 1] || {};
        const result = [strings[0]];
        keys.forEach((key, i) => {
            const value = Number.isInteger(key) ? values[key] : dict[key];
            result.push(value, strings[i + 1]);
        });
        return result.join('');
    };
}

/** Type for vernacular string constants */
export type VernacularConstants<T> = {
    [locale.en]: T;
    [locale.hi]?: {
        [x in keyof T]?: string | ReturnType<typeof template>;
    };
};

/**
 * Returns a valid locale from string and defaults
 * to English.
 *
 * @param lang
 */
export const getLocale = (lang: string) => {
    switch (lang) {
        case locale.hi:
            return locale.hi;
        default:
            return locale.en;
    }
};

/**
 * Global constants
 */
const globalConstants: VernacularConstants<typeof englishConstants> = {
    en: englishConstants,
};

/**
 * Function to extend global constants with local constants
 * @param localConstants
 */
export function getConstantValue<T>(localConstants?: VernacularConstants<T>) {
    const searchParam =
        typeof window !== 'undefined' ? window.location.search : '';
    const query = new URLSearchParams(searchParam);
    const currLocale = getLocale(query.get('lang'));

    if (currLocale !== 'en') {
        return {
            ...globalConstants.en,
            ...localConstants?.en,
            ...globalConstants[currLocale],
            ...localConstants?.[currLocale],
        };
    }

    return {
        ...globalConstants[currLocale],
        ...localConstants?.[currLocale],
    };
}
