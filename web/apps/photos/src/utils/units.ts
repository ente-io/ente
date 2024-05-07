import { t } from "i18next";

const StorageUnits = ["B", "KB", "MB", "GB", "TB"];

const ONE_GB = 1024 * 1024 * 1024;

/**
 * Convert the given number of {@link bytes} to their equivalent GB string with
 * {@link precision}.
 *
 * The returned string does not have the GB prefix.
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
export function formattedBytes(bytes: number, precision = 2): string {
    if (bytes === 0 || isNaN(bytes)) {
        return "0 MB";
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + " " + sizes[i];
}

export function makeHumanReadableStorage(
    bytes: number,
    { roundUp } = { roundUp: false },
): string {
    if (bytes <= 0) {
        return `0 ${t("STORAGE_UNITS.MB")}`;
    }
    const i = Math.floor(Math.log(bytes) / Math.log(1024));

    let quantity = bytes / Math.pow(1024, i);
    let unit = StorageUnits[i];

    if (quantity > 100 && unit !== "GB") {
        quantity /= 1024;
        unit = StorageUnits[i + 1];
    }

    quantity = Number(quantity.toFixed(1));

    if (bytes >= 10 * ONE_GB) {
        if (roundUp) {
            quantity = Math.ceil(quantity);
        } else {
            quantity = Math.round(quantity);
        }
    }

    return `${quantity} ${t(`STORAGE_UNITS.${unit}`)}`;
}
