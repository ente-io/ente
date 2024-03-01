import i18n from "i18next";

const numberFormatter = new Intl.NumberFormat(i18n.language);

export function formatNumber(value: number): string {
    return numberFormatter.format(value);
}
