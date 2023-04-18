import { Language } from 'constants/locale';

import { getUserLocales } from 'get-user-locale';
import { getUserLocale } from 'utils/storage';

export function getBestPossibleUserLocale(): Language {
    const locale = getUserLocale();
    if (locale) {
        return locale;
    }
    const userLocales = getUserLocales();
    for (const lc of userLocales) {
        if (lc.startsWith('en')) {
            return Language.en;
        }
        if (lc.startsWith('fr')) {
            return Language.fr;
        }
    }
    return Language.en;
}
