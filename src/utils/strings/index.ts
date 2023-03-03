import { locale } from 'constants/locale';
import { getUserLocales } from 'get-user-locale';

export function formatNumberWithCommas(x: number) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export function getBestPossibleUserLocale() {
    const userLocale = getUserLocales();
    for (const lc of userLocale) {
        if (lc.startsWith('en')) {
            return locale.en;
        }
        if (lc.startsWith('fr')) {
            return locale.fr;
        }
    }
    return locale.en;
}
