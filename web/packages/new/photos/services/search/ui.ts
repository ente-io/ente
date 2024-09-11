import { t } from "i18next";
import { SuggestionType } from "./types";

/**
 * Return a localized label for the given suggestion {@link type}.
 */
export const labelForSuggestionType = (type: SuggestionType) => {
    switch (type) {
        case SuggestionType.DATE:
            return t("date");
        case SuggestionType.LOCATION:
            return t("location");
        case SuggestionType.CITY:
            return t("location");
        case SuggestionType.COLLECTION:
            return t("album");
        case SuggestionType.FILE_NAME:
            return t("file_name");
        case SuggestionType.PERSON:
            return t("person");
        case SuggestionType.FILE_CAPTION:
            return t("description");
        case SuggestionType.FILE_TYPE:
            return t("file_type");
        case SuggestionType.CLIP:
            return t("magic");
    }
};
