import { t } from "i18next";
import type { DialogBoxAttributesV2 } from "./DialogBoxV2/types";

/**
 * {@link DialogBoxAttributesV2} for showing a generic error.
 */
export const genericErrorAttributes = (): DialogBoxAttributesV2 => ({
    title: t("error"),
    close: { variant: "critical" },
    content: t("generic_error_retry"),
});
