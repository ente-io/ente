// TODO-cgroups
/* eslint-disable @typescript-eslint/no-non-null-assertion */
/* eslint-disable @typescript-eslint/prefer-includes */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { getUICreationDate } from "@/media/file-metadata";
import type {
    City,
    Location,
    LocationTagData,
} from "@/new/photos/services/search/types";
import type { EnteFile } from "@/new/photos/types/file";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import { expose } from "comlink";
import type { SearchDateComponents, SearchQuery } from "./types";

/**
 * A web worker that runs the search asynchronously so that the main thread
 * remains responsive.
 */
export class SearchWorker {
    private enteFiles: EnteFile[] = [];

    /**
     * Set the files that we should search across.
     */
    setEnteFiles(enteFiles: EnteFile[]) {
        this.enteFiles = enteFiles;
    }

    /**
     * Return {@link EnteFile}s that satisfy the given {@link searchQuery}
     * query.
     */
    search(searchQuery: SearchQuery) {
        return this.enteFiles.filter((f) => isMatch(f, searchQuery));
    }
}

expose(SearchWorker);

function isMatch(file: EnteFile, query: SearchQuery) {
    if (query?.collection) {
        return query.collection === file.collectionID;
    }

    if (query?.date) {
        return isDateComponentsMatch(
            query.date,
            getUICreationDate(file, getPublicMagicMetadataSync(file)),
        );
    }
    if (query?.location) {
        return isInsideLocationTag(
            {
                latitude: file.metadata.latitude ?? null,
                longitude: file.metadata.longitude ?? null,
            },
            query.location,
        );
    }
    if (query?.city) {
        return isInsideCity(
            {
                latitude: file.metadata.latitude ?? null,
                longitude: file.metadata.longitude ?? null,
            },
            query.city,
        );
    }
    if (query?.files) {
        return query.files.indexOf(file.id) !== -1;
    }
    if (query?.person) {
        return query.person.files.indexOf(file.id) !== -1;
    }
    if (typeof query?.fileType !== "undefined") {
        return query.fileType === file.metadata.fileType;
    }
    if (typeof query?.clip !== "undefined") {
        return query.clip.has(file.id);
    }
    return false;
}

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

export function isInsideLocationTag(
    location: Location,
    locationTag: LocationTagData,
) {
    return isLocationCloseToPoint(
        location,
        locationTag.centerPoint,
        locationTag.radius,
    );
}

const DEFAULT_CITY_RADIUS = 10;
const KMS_PER_DEGREE = 111.16;

export function isInsideCity(location: Location, city: City) {
    return isLocationCloseToPoint(
        { latitude: city.lat, longitude: city.lng },
        location,
        DEFAULT_CITY_RADIUS,
    );
}

function isLocationCloseToPoint(
    centerPoint: Location,
    location: Location,
    radius: number,
) {
    const a = (radius * _scaleFactor(centerPoint.latitude!)) / KMS_PER_DEGREE;
    const b = radius / KMS_PER_DEGREE;
    const x = centerPoint.latitude! - location.latitude!;
    const y = centerPoint.longitude! - location.longitude!;
    if ((x * x) / (a * a) + (y * y) / (b * b) <= 1) {
        return true;
    }
    return false;
}

///The area bounded by the location tag becomes more elliptical with increase
///in the magnitude of the latitude on the caritesian plane. When latitude is
///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
///the major axis (a) has to be scaled by the secant of the latitude.
function _scaleFactor(lat: number) {
    return 1 / Math.cos(lat * (Math.PI / 180));
}
