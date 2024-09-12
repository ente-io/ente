import { HTTPError } from "@/base/http";
import type { Location } from "@/base/types";
import type { Collection } from "@/media/collection";
import { fileCreationPhotoDate, fileLocation } from "@/media/file-metadata";
import type { EnteFile } from "@/new/photos/types/file";
import { ensure } from "@/utils/ensure";
import { nullToUndefined } from "@/utils/transform";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import { expose } from "comlink";
import { z } from "zod";
import {
    pullLocationTags,
    savedLocationTags,
    type LocationTag,
} from "../user-entity";
import type {
    City,
    LabelledFileType,
    LabelledSearchDateComponents,
    LocalizedSearchData,
    Searchable,
    SearchableData,
    SearchDateComponents,
    SearchSuggestion,
} from "./types";

/**
 * A web worker that runs the search asynchronously so that the main thread
 * remains responsive.
 */
export class SearchWorker {
    private searchableData: SearchableData = { collections: [], files: [] };
    private locationTags: Searchable<LocationTag>[] = [];
    private cities: Searchable<City>[] = [];

    /**
     * Fetch any state we might need when the actual search happens.
     *
     * @param masterKey The user's master key. Web workers do not have access to
     * session storage so this key needs to be passed to us explicitly.
     */
    async sync(masterKey: Uint8Array) {
        return Promise.all([
            pullLocationTags(masterKey)
                .then(() => savedLocationTags())
                .then((ts) => {
                    this.locationTags = ts.map((t) => ({
                        ...t,
                        lowercasedName: t.name.toLowerCase(),
                    }));
                }),
            fetchCities().then((cs) => {
                this.cities = cs.map((c) => ({
                    ...c,
                    lowercasedName: c.name.toLowerCase(),
                }));
            }),
        ]);
    }

    /**
     * Set the data that we should search across.
     */
    setSearchableData(data: SearchableData) {
        this.searchableData = data;
    }

    /**
     * Convert a search string into a list of {@link SearchSuggestion}s.
     */
    suggestionsForString(
        s: string,
        searchString: string,
        localizedSearchData: LocalizedSearchData,
    ) {
        return suggestionsForString(
            s,
            searchString,
            this.searchableData,
            localizedSearchData,
            this.locationTags,
            this.cities,
        );
    }

    /**
     * Return {@link EnteFile}s that satisfy the given {@link suggestion}.
     */
    filterSearchableFiles(suggestion: SearchSuggestion) {
        return sortMatchesIfNeeded(
            this.searchableData.files.filter((f) =>
                isMatchingFile(f, suggestion),
            ),
            suggestion,
        );
    }
}

expose(SearchWorker);

/**
 * @param s The normalized form of {@link searchString}.
 * @param searchString The original search string.
 */
const suggestionsForString = (
    s: string,
    searchString: string,
    { collections, files }: SearchableData,
    { locale, holidays, labelledFileTypes }: LocalizedSearchData,
    locationTags: Searchable<LocationTag>[],
    cities: Searchable<City>[],
): SearchSuggestion[] =>
    [
        // <-- caption suggestions will be inserted here by our caller.
        fileTypeSuggestions(s, labelledFileTypes),
        dateSuggestions(s, locale, holidays),
        locationSuggestions(s, locationTags, cities),
        collectionSuggestions(s, collections),
        fileNameSuggestion(s, searchString, files),
        fileCaptionSuggestion(s, searchString, files),
    ].flat();

const collectionSuggestions = (
    s: string,
    collections: Collection[],
): SearchSuggestion[] =>
    collections
        .filter(({ name }) => name.toLowerCase().includes(s))
        .map(({ id, name }) => ({
            type: "collection",
            collectionID: id,
            label: name,
        }));

const fileTypeSuggestions = (
    s: string,
    labelledFileTypes: Searchable<LabelledFileType>[],
): SearchSuggestion[] =>
    labelledFileTypes
        .filter(({ lowercasedName }) => lowercasedName.startsWith(s))
        .map(({ fileType, label }) => ({ type: "fileType", fileType, label }));

const fileNameSuggestion = (
    s: string,
    searchString: string,
    files: EnteFile[],
): SearchSuggestion[] => {
    // Convert the search string to a number. This allows searching a file by
    // its exact (integral) ID.
    const sn = Number(s) || undefined;

    const fileIDs = files
        .filter(
            ({ id, metadata }) =>
                id === sn || metadata.title.toLowerCase().includes(s),
        )
        .map((f) => f.id);

    return fileIDs.length
        ? [{ type: "fileName", fileIDs, label: searchString }]
        : [];
};

const fileCaptionSuggestion = (
    s: string,
    searchString: string,
    files: EnteFile[],
): SearchSuggestion[] => {
    const fileIDs = files
        .filter((file) =>
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            file.pubMagicMetadata?.data?.caption?.toLowerCase().includes(s),
        )
        .map((f) => f.id);

    return fileIDs.length
        ? [{ type: "fileCaption", fileIDs, label: searchString }]
        : [];
};

const dateSuggestions = (
    s: string,
    locale: string,
    holidays: Searchable<LabelledSearchDateComponents>[],
): SearchSuggestion[] =>
    parseDateComponents(s, locale, holidays).map(({ components, label }) => ({
        type: "date",
        dateComponents: components,
        label,
    }));

/**
 * Try to parse an arbitrary search string into sets of date components.
 *
 * e.g. "December 2022" will be parsed into a
 *
 *     [(year 2022, month 12, day undefined)]
 *
 * while "22 December 2022" will be parsed into
 *
 *     [(year 2022, month 12, day 22)]
 *
 * In addition, also return a formatted representation of the "best" guess at
 * the date that was intended by the search string.
 */
const parseDateComponents = (
    s: string,
    locale: string,
    holidays: Searchable<LabelledSearchDateComponents>[],
): LabelledSearchDateComponents[] =>
    [
        parseChrono(s, locale),
        parseYearComponents(s),
        holidays.filter(searchableIncludes(s)),
    ].flat();

const parseChrono = (
    s: string,
    locale: string,
): LabelledSearchDateComponents[] =>
    chrono
        .parse(s)
        .map((result) => {
            const p = result.start;
            const component = (s: Component) =>
                p.isCertain(s) ? nullToUndefined(p.get(s)) : undefined;

            const year = component("year");
            const month = component("month");
            const day = component("day");
            const weekday = component("weekday");
            const hour = component("hour");

            if (!year && !month && !day && !weekday && !hour) return undefined;
            const components = { year, month, day, weekday, hour };

            const format: Intl.DateTimeFormatOptions = {};
            if (year) format.year = "numeric";
            if (month) format.month = "long";
            if (day) format.day = "numeric";
            if (weekday) format.weekday = "long";
            if (hour) {
                format.hour = "numeric";
                format.dayPeriod = "short";
            }

            const formatter = new Intl.DateTimeFormat(locale, format);
            const label = formatter.format(p.date());
            return { components, label };
        })
        .filter((x) => x !== undefined);

/** chrono does not parse years like "2024", so do it manually. */
const parseYearComponents = (s: string): LabelledSearchDateComponents[] => {
    // s is already trimmed.
    if (s.length == 4) {
        const year = parseInt(s);
        if (year && year <= 9999) {
            const components = { year };
            return [{ components, label: s }];
        }
    }
    return [];
};

/**
 * A helper function to directly pass to filters on Searchable<T>[].
 */
const searchableIncludes =
    (s: string) =>
    ({ lowercasedName }: { lowercasedName: string }) =>
        lowercasedName.includes(s);

/**
 * Zod schema describing world_cities.json.
 *
 * The entries also have a country field which we don't currently use.
 */
const RemoteWorldCities = z.object({
    data: z.array(
        z.object({
            city: z.string(),
            lat: z.number(),
            lng: z.number(),
        }),
    ),
});

const fetchCities = async () => {
    const res = await fetch("https://static.ente.io/world_cities.json");
    if (!res.ok) throw new HTTPError(res);
    return RemoteWorldCities.parse(await res.json()).data.map(
        ({ city, lat, lng }) => ({ name: city, latitude: lat, longitude: lng }),
    );
};

const locationSuggestions = (
    s: string,
    locationTags: Searchable<LocationTag>[],
    cities: Searchable<City>[],
): SearchSuggestion[] => {
    const matchingLocationTags = locationTags.filter(searchableIncludes(s));

    const matchingLocationTagLNames = new Set(
        matchingLocationTags.map((t) => t.lowercasedName),
    );

    const matchingCities = cities.filter(
        (c) =>
            c.lowercasedName.startsWith(s) &&
            !matchingLocationTagLNames.has(c.lowercasedName),
    );

    return [
        matchingLocationTags.map(
            (locationTag): SearchSuggestion => ({
                type: "location",
                locationTag,
                label: locationTag.name,
            }),
        ),
        matchingCities.map(
            (city): SearchSuggestion => ({
                type: "city",
                city,
                label: city.name,
            }),
        ),
    ].flat();
};

/**
 * Return true if file satisfies the given {@link query}.
 */
const isMatchingFile = (file: EnteFile, suggestion: SearchSuggestion) => {
    switch (suggestion.type) {
        case "collection":
            return suggestion.collectionID === file.collectionID;

        case "fileType":
            return suggestion.fileType === file.metadata.fileType;

        case "fileName":
            return suggestion.fileIDs.includes(file.id);

        case "fileCaption":
            return suggestion.fileIDs.includes(file.id);

        case "date":
            return isDateComponentsMatch(
                suggestion.dateComponents,
                fileCreationPhotoDate(file, getPublicMagicMetadataSync(file)),
            );

        case "location": {
            const location = fileLocation(file);
            if (!location) return false;

            return isInsideLocationTag(location, suggestion.locationTag);
        }

        case "city": {
            const location = fileLocation(file);
            if (!location) return false;

            return isInsideCity(location, suggestion.city);
        }

        case "clip":
            return suggestion.clipScoreForFileID.has(file.id);

        case "cgroup":
            // return query.person.files.includes(file.id);
            // TODO-Cluster implement me
            return false;
    }
};

const isDateComponentsMatch = (
    { year, month, day, weekday, hour }: SearchDateComponents,
    date: Date,
) => {
    // Components are guaranteed to have at least one attribute present, so
    // start by assuming true.
    let match = true;

    if (year) match = date.getFullYear() == year;
    // JS getMonth is 0-indexed.
    if (match && month) match = date.getMonth() + 1 == month;
    if (match && day) match = date.getDate() == day;
    if (match && weekday) match = date.getDay() == weekday;
    if (match && hour) match = date.getHours() == hour;

    return match;
};

const defaultCityRadius = 10;
const kmsPerDegree = 111.16;

const isInsideLocationTag = (location: Location, locationTag: LocationTag) =>
    // This code is included in the photos app which currently doesn't have
    // strict mode, and causes a spurious linter warning (but only when included
    // in photos!), so we need to ts-ignore.
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    isWithinRadius(location, locationTag.centerPoint, locationTag.radius);

const isInsideCity = (location: Location, city: City) =>
    isWithinRadius(location, city, defaultCityRadius);

const isWithinRadius = (
    location: Location,
    center: Location,
    radius: number,
) => {
    const a = (radius * radiusScaleFactor(center.latitude)) / kmsPerDegree;
    const b = radius / kmsPerDegree;
    const x = center.latitude - location.latitude;
    const y = center.longitude - location.longitude;
    return (x * x) / (a * a) + (y * y) / (b * b) <= 1;
};

/**
 * A latitude specific scaling factor to apply to the radius of a location
 * search.
 *
 * The area bounded by the location tag becomes more elliptical with increase in
 * the magnitude of the latitude on the cartesian plane. When latitude is 0
 * degrees, the ellipse is a circle with a = b = r. When latitude incrases, the
 * major axis (a) has to be scaled by the secant of the latitude.
 */
const radiusScaleFactor = (lat: number) => 1 / Math.cos(lat * (Math.PI / 180));

/**
 * Sort the files if necessary.
 *
 * Currently, only the CLIP results are sorted (by their score), in the other
 * cases the files are displayed chronologically (when displaying them in search
 * results) or arbitrarily (when showing them in the search option preview).
 */
const sortMatchesIfNeeded = (
    files: EnteFile[],
    suggestion: SearchSuggestion,
) => {
    if (suggestion.type != "clip") return files;
    // Sort CLIP matches by their corresponding scores.
    const score = ({ id }: EnteFile) =>
        ensure(suggestion.clipScoreForFileID.get(id));
    return files.sort((a, b) => score(b) - score(a));
};
