import { t } from "i18next";

/**
 * Localized unit keys.
 *
 * For each of these, there is expected to be a localized key under
 * "storage_unit". e.g. "storage_unit.tb".
 */
const units = ["b", "kb", "mb", "gb", "tb"];

/**
 * Convert the given number of {@link bytes} to a user visible string in an
 * appropriately sized unit.
 *
 * The returned string includes the (localized) unit suffix, e.g. "TB".
 *
 * @param precision Modify the number of digits after the decimal point.
 * Defaults to 2.
 */
export function formattedByteSize(bytes: number, precision = 2): string {
    if (bytes <= 0) return `0 ${t("storage_unit.mb")}`;

    const i = Math.min(
        Math.floor(Math.log(bytes) / Math.log(1024)),
        units.length - 1,
    );
    const quantity = bytes / Math.pow(1024, i);
    const unit = units[i];

    return `${quantity.toFixed(precision)} ${t(`storage_unit.${unit}`)}`;
}
