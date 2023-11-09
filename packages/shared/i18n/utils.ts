import { Language } from './locale';

import { getUserLocales } from 'get-user-locale';
import { getUserLocale } from '@ente/shared/storage/localStorage/helpers';

export function getBestPossibleUserLocale(): Language {
    const locale = getUserLocale();
    if (locale) {
        return locale;
    }
    const userLocales = getUserLocales();
    for (const lc of userLocales) {
        if (lc.startsWith('en')) {
            return Language.en;
        } else if (lc.startsWith('fr')) {
            return Language.fr;
        } else if (lc.startsWith('zh')) {
            return Language.zh;
        } else if (lc.startsWith('nl')) {
            return Language.nl;
        } else if (lc.startsWith('es')) {
            return Language.es;
        }
    }
    return Language.en;
}
