// TODO-cgroups
/* eslint-disable @typescript-eslint/no-non-null-assertion */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { HTTPError } from "@/base/http";
import { fileCreationPhotoDate, fileLocation } from "@/media/file-metadata";
import type { EnteFile } from "@/new/photos/types/file";
import { wait } from "@/utils/promise";
import { nullToUndefined } from "@/utils/transform";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import { expose } from "comlink";
import { z } from "zod";
import type {
    City,
    DateSearchResult,
    LocationOld,
    LocationTagData,
    SearchDateComponents,
    SearchQuery,
    Suggestion,
} from "./types";
import { SuggestionType } from "./types";

/**
 * A web worker that runs the search asynchronously so that the main thread
 * remains responsive.
 */
export class SearchWorker {
    private enteFiles: EnteFile[] = [];
    private cities: City[] = [];
    private citiesPromise: Promise<void> | undefined;

    /**
     * Set the files that we should search across.
     */
    setEnteFiles(enteFiles: EnteFile[]) {
        this.enteFiles = enteFiles;
    }

    /**
     * Convert a search string into a reusable query.
     */
    async createSearchQuery(
        searchString: string,
        locale: string,
        holidays: DateSearchResult[],
    ) {
        this.triggerCityFetchIfNeeded();
        return createSearchQuery(searchString, locale, holidays, this.cities);
    }

    /**
     * Lazily trigger a fetch of city data, but don't wait for it to complete.
     */
    triggerCityFetchIfNeeded() {
        if (this.citiesPromise) return;
        this.citiesPromise = fetchCities().then((cs) => {
            this.cities = cs;
        });
    }

    /**
     * Return {@link EnteFile}s that satisfy the given {@link searchQuery}.
     */
    search(searchQuery: SearchQuery) {
        return this.enteFiles.filter((f) => isMatch(f, searchQuery));
    }
}

expose(SearchWorker);

const createSearchQuery = async (
    searchString: string,
    locale: string,
    holidays: DateSearchResult[],
    cities: City[],
): Promise<Suggestion[]> => {
    // Normalize it by trimming whitespace and converting to lowercase.
    const s = searchString.trim().toLowerCase();
    if (s.length == 0) return [];

    // TODO Temp
    await wait(0);
    return [dateSuggestions(s, locale, holidays)].flat();
};

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
        ({ city, lat, lng }) => ({
            name: city,
            lowercasedName: city.toLowerCase(),
            latitude: lat,
            longitude: lng,
        }),
    );
};

/**
 * Return all cities whose name begins with the given search string.
 */
const matchingCities = (s: string, cities: City[]) =>
    cities.filter(({ lowercasedName }) => lowercasedName.startsWith(s));

const isMatch = (file: EnteFile, query: SearchQuery) => {
    if (query?.collection) {
        return query.collection === file.collectionID;
    }

    if (query?.date) {
        return isDateComponentsMatch(
            query.date,
            fileCreationPhotoDate(file, getPublicMagicMetadataSync(file)),
        );
    }

    if (query?.location) {
        const location = fileLocation(file);
        if (!location) return false;

        return isInsideLocationTag(location, query.location);
    }

    if (query?.city) {
        const location = fileLocation(file);
        if (!location) return false;

        return isInsideCity(location, query.city);
    }

    if (query?.files) {
        return query.files.includes(file.id);
    }

    if (query?.person) {
        return query.person.files.includes(file.id);
    }

    if (typeof query?.fileType !== "undefined") {
        return query.fileType === file.metadata.fileType;
    }

    if (typeof query?.clip !== "undefined") {
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

const isInsideLocationTag = (
    location: LocationOld,
    locationTag: LocationTagData,
) => isWithinRadius(location, locationTag.centerPoint, locationTag.radius);

const isInsideCity = (location: LocationOld, city: City) =>
    isWithinRadius(city, location, defaultCityRadius);

const isWithinRadius = (
    centerPoint: LocationOld,
    location: LocationOld,
    radius: number,
) => {
    const a =
        (radius * radiusScaleFactor(centerPoint.latitude!)) / kmsPerDegree;
    const b = radius / kmsPerDegree;
    const x = centerPoint.latitude! - location.latitude!;
    const y = centerPoint.longitude! - location.longitude!;
    return (x * x) / (a * a) + (y * y) / (b * b) <= 1;
};

/**
 * A latitude specific scaling factor to apply to the radius of a location
 * search.
 *
 * The area bounded by the location tag becomes more elliptical with increase in
 * the magnitude of the latitude on the caritesian plane. When latitude is 0
 * degrees, the ellipse is a circle with a = b = r. When latitude incrases, the
 * major axis (a) has to be scaled by the secant of the latitude.
 */
const radiusScaleFactor = (lat: number) => 1 / Math.cos(lat * (Math.PI / 180));
