import { t } from "i18next";

const StorageUnits = ["B", "KB", "MB", "GB", "TB"];

const ONE_GB = 1024 * 1024 * 1024;

export function convertBytesToGBs(bytes: number, precision = 0): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision);
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
