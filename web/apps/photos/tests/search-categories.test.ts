import type {
    SearchOption,
    SearchSuggestion,
} from "ente-new/photos/services/search/types";
import { describe, expect, test } from "vitest";
import {
    groupSearchOptions,
    matchesSearchCategory,
    searchCategories,
    searchCategoryCounts,
    searchCategoryForType,
    type SearchCategory,
} from "../src/services/search/search-categories";

const categoriesByType = {
    collection: "albums",
    person: "people",
    location: "places",
    city: "places",
    sidebarAction: "settings",
    fileType: "photos",
    fileName: "photos",
    fileCaption: "photos",
    cameraMake: "photos",
    cameraModel: "photos",
    date: "photos",
    noLocation: "photos",
    clip: "photos",
} satisfies Record<SearchSuggestion["type"], Exclude<SearchCategory, "all">>;

const option = (type: SearchSuggestion["type"], fileCount = 100) =>
    ({
        suggestion: { type, label: type },
        fileCount,
        previewFiles: [],
    }) as SearchOption;

describe("search categories", () => {
    test.each(Object.entries(categoriesByType))(
        "maps %s to %s",
        (type, category) => {
            expect(
                searchCategoryForType(type as SearchSuggestion["type"]),
            ).toBe(category);
        },
    );

    test("filters without reordering or changing the source results", () => {
        const options = [
            option("city"),
            option("fileName"),
            option("collection"),
            option("location"),
            option("person"),
            option("sidebarAction"),
            option("clip"),
        ];
        const original = [...options];
        for (const category of searchCategories) {
            const expected =
                category === "all"
                    ? options
                    : options.filter(
                          (o) =>
                              categoriesByType[o.suggestion.type] === category,
                      );
            const filtered = options.filter((o) =>
                matchesSearchCategory(o, category),
            );
            expect(filtered).toEqual(expected);
            filtered.forEach((o, index) => expect(o).toBe(expected[index]));
        }
        expect(options).toEqual(original);
    });

    test("counts suggestions across the complete list, including empty categories", () => {
        expect(
            searchCategoryCounts([
                option("city", 200),
                option("location", 300),
                option("clip", 500),
                option("collection", 1000),
            ]),
        ).toEqual({
            all: 4,
            albums: 1,
            people: 0,
            places: 2,
            photos: 1,
            settings: 0,
        });
        expect(searchCategoryCounts([])).toEqual({
            all: 0,
            albums: 0,
            people: 0,
            places: 0,
            photos: 0,
            settings: 0,
        });
    });
});

test("groups results in tab order while preserving rows within each category", () => {
    const firstPhoto = option("clip");
    const secondPhoto = option("fileName");
    const album = option("collection");
    const place = option("city");
    const setting = option("sidebarAction");
    const options = [firstPhoto, setting, place, secondPhoto, album];
    expect(groupSearchOptions(options)).toEqual([
        { label: "albums", options: [album] },
        { label: "places", options: [place] },
        { label: "photos", options: [firstPhoto, secondPhoto] },
        { label: "settings", options: [setting] },
    ]);
    expect(options).toEqual([firstPhoto, setting, place, secondPhoto, album]);
    expect(groupSearchOptions([])).toEqual([]);
});
