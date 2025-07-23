import { t } from "i18next";

/**
 * Localized unit keys.
 *
 * For each of these, there is expected to be a localized key under
 * "storage_unit". e.g. "storage_unit.tb".
 */
const units = ["b", "kb", "mb", "gb", "tb"];

/**
 * Convert the given number of {@link bytes} to their equivalent GB string with
 * {@link precision}.
 *
 * The returned string does not have the GB suffix.
 */
export const bytesInGB = (bytes: number, precision = 0): string =>
    (bytes / (1024 * 1024 * 1024)).toFixed(precision);

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

interface FormattedStorageByteSizeOptions {
    /**
     * If `true` then round up the fractional quantity we obtain when dividing
     * the number of bytes by the number of bytes in the unit that got chosen.
     *
     * The default behaviour is to take the ceiling.
     */
    round?: boolean;
}

/**
 * Convert the given number of storage {@link bytes} to a user visible string in
 * an appropriately sized unit.
 *
 * This differs from {@link formattedByteSize} in that while
 * {@link formattedByteSize} is meant for arbitrary byte sizes, this function
 * has a few additional beautification heuristics that we want to apply when
 * displaying the "storage size" (in different contexts) as opposed to, say, a
 * generic "file size".
 *
 * @param options {@link FormattedStorageByteSizeOptions}.
 *
 * @return A user visible string, including the localized unit suffix.
 */
export const formattedStorageByteSize = (
    bytes: number,
    options?: FormattedStorageByteSizeOptions,
): string => {
    if (bytes <= 0) return `0 ${t("storage_unit.mb")}`;

    const i = Math.min(
        Math.floor(Math.log(bytes) / Math.log(1024)),
        units.length - 1,
    );

    let quantity = bytes / Math.pow(1024, i);
    let unit = units[i];

    // Round up bytes, KBs and MBs to the bigger unit whenever they'll come of
    // as more than 0.1.
    if (quantity > 100 && i < units.length - 2) {
        quantity /= 1024;
        unit = units[i + 1];
    }

    quantity = Number(quantity.toFixed(1));

    // Truncate or round storage sizes to trim off unnecessary and potentially
    // obscuring precision when they are larger that 10 GB.
    if (bytes >= 10 * 1024 * 1024 * 1024 /* 10 GB */) {
        if (options?.round) {
            quantity = Math.ceil(quantity);
        } else {
            quantity = Math.round(quantity);
        }
    }

    return `${quantity} ${t(`storage_unit.${unit}`)}`;
};
