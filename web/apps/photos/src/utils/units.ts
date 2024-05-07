import { t } from "i18next";

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
    if (bytes === 0 || isNaN(bytes)) {
        return "0 MB";
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + " " + sizes[i];
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
 * @param options
 *
 * @return A user visible string, including the localized unit suffix.
 */
export const formattedStorageByteSize = (
    bytes: number,
    options?: FormattedStorageByteSizeOptions,
): string => {
    if (bytes <= 0) {
        return `0 ${t("storage_unit.mb")}`;
    }
    const i = Math.floor(Math.log(bytes) / Math.log(1024));

    let quantity = bytes / Math.pow(1024, i);
    let unit = units[i];

    if (quantity > 100 && unit !== "GB") {
        quantity /= 1024;
        unit = units[i + 1];
    }

    quantity = Number(quantity.toFixed(1));

    if (bytes >= 10 * 1024 * 1024 * 1024 /* 10 GB */) {
        if (options?.round) {
            quantity = Math.ceil(quantity);
        } else {
            quantity = Math.round(quantity);
        }
    }

    return `${quantity} ${t(`storage_unit.${unit}`)}`;
};
