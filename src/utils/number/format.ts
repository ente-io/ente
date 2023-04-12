import i18n from 'i18next';

export function formatNumber(value: number): string {
    return new Intl.NumberFormat(i18n.language).format(value);
}
