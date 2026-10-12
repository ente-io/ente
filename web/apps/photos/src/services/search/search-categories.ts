import type {
    SearchOption,
    SearchSuggestion,
} from "ente-new/photos/services/search/types";

export const searchCategories = [
    "all",
    "albums",
    "people",
    "places",
    "photos",
    "settings",
] as const;

export type SearchCategory = (typeof searchCategories)[number];

export const searchCategoryForType = (
    type: SearchSuggestion["type"],
): Exclude<SearchCategory, "all"> => {
    switch (type) {
        case "collection":
            return "albums";
        case "person":
            return "people";
        case "location":
        case "city":
            return "places";
        case "sidebarAction":
            return "settings";
        default:
            return "photos";
    }
};

export const matchesSearchCategory = (
    option: SearchOption,
    category: SearchCategory,
) =>
    category === "all" ||
    searchCategoryForType(option.suggestion.type) === category;

export const searchCategoryCounts = (options: readonly SearchOption[]) => {
    const counts = {
        all: options.length,
        albums: 0,
        people: 0,
        places: 0,
        photos: 0,
        settings: 0,
    };
    for (const option of options)
        counts[searchCategoryForType(option.suggestion.type)]++;
    return counts;
};

export const groupSearchOptions = (options: readonly SearchOption[]) =>
    searchCategories
        .filter((category) => category !== "all")
        .map((category) => ({
            label: category,
            options: options.filter((option) =>
                matchesSearchCategory(option, category),
            ),
        }))
        .filter((group) => group.options.length > 0);
