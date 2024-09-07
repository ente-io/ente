import { t } from "i18next";
import { SuggestionType } from "./types";

/**
 * Return a localized label for the given suggestion {@link type}.
 */
export const labelForSuggestionType = (type: SuggestionType) => {
    switch (type) {
        case SuggestionType.DATE:
            return t("SEARCH_TYPE.DATE");
        case SuggestionType.LOCATION:
            return t("location");
        case SuggestionType.CITY:
            return t("location");
        case SuggestionType.COLLECTION:
            return t("SEARCH_TYPE.COLLECTION");
        case SuggestionType.FILE_NAME:
            return t("file_name");
        case SuggestionType.PERSON:
            return t("SEARCH_TYPE.PERSON");
        case SuggestionType.INDEX_STATUS:
            return t("SEARCH_TYPE.INDEX_STATUS");
        case SuggestionType.FILE_CAPTION:
            return t("SEARCH_TYPE.FILE_CAPTION");
        case SuggestionType.FILE_TYPE:
            return t("SEARCH_TYPE.FILE_TYPE");
        case SuggestionType.CLIP:
            return t("SEARCH_TYPE.CLIP");
    }
};
