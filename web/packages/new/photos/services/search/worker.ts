import { HTTPError } from "@/base/http";
import type { Location } from "@/base/types";
import { fileCreationPhotoDate, fileLocation } from "@/media/file-metadata";
import type { EnteFile } from "@/new/photos/types/file";
import { nullToUndefined } from "@/utils/transform";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import { expose } from "comlink";
import { z } from "zod";
import {
    savedLocationTags,
    syncLocationTags,
    type LocationTag,
} from "../user-entity";
import type {
    City,
    DateSearchResult,
    SearchDateComponents,
    SearchQuery,
    Suggestion,
} from "./types";
import { SuggestionType } from "./types";

type SearchableCity = City & {
    /**
     * Name of the city, lowercased. Precomputed to save an op during search.
     */
    lowercasedName: string;
};

type SearchableLocationTag = LocationTag & {
    /**
     * Name of the location tag, lowercased. Precomputed to save an op during
     * search.
     */
    lowercasedName: string;
};

/**
 * A web worker that runs the search asynchronously so that the main thread
 * remains responsive.
 */
export class SearchWorker {
    private enteFiles: EnteFile[] = [];
    private locationTags: SearchableLocationTag[] = [];
    private cities: SearchableCity[] = [];

    /**
     * Fetch any state we might need when the actual search happens.
     *
     * @param masterKey The user's master key. Web workers do not have access to
     * session storage so this key needs to be passed to us explicitly.
     */
    async sync(masterKey: Uint8Array) {
        return Promise.all([
            syncLocationTags(masterKey)
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
     * Set the files that we should search across.
     */
    setEnteFiles(enteFiles: EnteFile[]) {
        this.enteFiles = enteFiles;
    }

    /**
     * Convert a search string into a reusable query.
     */
    createSearchQuery(s: string, locale: string, holidays: DateSearchResult[]) {
        return createSearchQuery(
            s,
            locale,
            holidays,
            this.locationTags,
            this.cities,
        );
    }

    /**
     * Return {@link EnteFile}s that satisfy the given {@link searchQuery}.
     */
    search(searchQuery: SearchQuery) {
        return this.enteFiles.filter((f) => isMatchingFile(f, searchQuery));
    }
}

expose(SearchWorker);

const createSearchQuery = (
    s: string,
    locale: string,
    holidays: DateSearchResult[],
    locationTags: SearchableLocationTag[],
    cities: SearchableCity[],
): Suggestion[] =>
    [
        dateSuggestions(s, locale, holidays),
        locationSuggestions(s, locationTags, cities),
    ].flat();

const dateSuggestions = (
    s: string,
    locale: string,
    holidays: DateSearchResult[],
) =>
    parseDateComponents(s, locale, holidays).map(({ components, label }) => ({
        type: SuggestionType.DATE,
        value: components,
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
    holidays: DateSearchResult[],
): DateSearchResult[] =>
    [
        parseChrono(s, locale),
        parseYearComponents(s),
        parseHolidayComponents(s, holidays),
    ].flat();

const parseChrono = (s: string, locale: string): DateSearchResult[] =>
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
const parseYearComponents = (s: string): DateSearchResult[] => {
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

const parseHolidayComponents = (s: string, holidays: DateSearchResult[]) =>
    holidays.filter(({ label }) => label.toLowerCase().includes(s));

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
    locationTags: SearchableLocationTag[],
    cities: SearchableCity[],
) => {
    const matchingLocationTags = locationTags.filter((t) =>
        t.lowercasedName.includes(s),
    );

    const matchingLocationTagLNames = new Set(
        matchingLocationTags.map((t) => t.lowercasedName),
    );

    const matchingCities = cities.filter(
        (c) =>
            c.lowercasedName.startsWith(s) &&
            !matchingLocationTagLNames.has(c.lowercasedName),
    );

    return [
        matchingLocationTags.map((t) => ({
            type: SuggestionType.LOCATION,
            value: t,
            label: t.name,
        })),
        matchingCities.map((c) => ({
            type: SuggestionType.CITY,
            value: c,
            label: c.name,
        })),
    ].flat();
};

/**
 * Return true if file satisfies the given {@link query}.
 */
const isMatchingFile = (file: EnteFile, query: SearchQuery) => {
    if (query.collection) {
        return query.collection === file.collectionID;
    }

    if (query.date) {
        return isDateComponentsMatch(
            query.date,
            fileCreationPhotoDate(file, getPublicMagicMetadataSync(file)),
        );
    }

    if (query.location) {
        const location = fileLocation(file);
        if (!location) return false;

        return isInsideLocationTag(location, query.location);
    }

    if (query.city) {
        const location = fileLocation(file);
        if (!location) return false;

        return isInsideCity(location, query.city);
    }

    if (query.files) {
        return query.files.includes(file.id);
    }

    if (query.person) {
        return query.person.files.includes(file.id);
    }

    if (typeof query.fileType !== "undefined") {
        return query.fileType === file.metadata.fileType;
    }

    if (typeof query.clip !== "undefined") {
        return query.clip.has(file.id);
    }

    return false;
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
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment, @typescript-eslint/prefer-ts-expect-error
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
