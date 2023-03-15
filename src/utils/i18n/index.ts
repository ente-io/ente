import { Language } from 'constants/locale';

import { getUserLocales } from 'get-user-locale';

export function getBestPossibleUserLocale(): Language {
    const userLocales = getUserLocales();
    for (const lc of userLocales) {
        if (lc.startsWith('en')) {
            return Language.en;
        }
        if (lc.startsWith('fr')) {
            return Language.fr;
        }
    }
}
