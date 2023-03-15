import { Language } from 'constants/locale';

export function getBestPossibleUserLocale(
    userLocales: readonly string[]
): Language {
    for (const lc of userLocales) {
        if (lc.startsWith('en')) {
            return Language.en;
        }
        if (lc.startsWith('fr')) {
            return Language.fr;
        }
    }
}
