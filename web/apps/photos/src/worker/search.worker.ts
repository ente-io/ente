import { getUICreationDate } from "@/media/file-metadata";
import type { SearchDateComponents } from "@/new/photos/services/search/types";
import { EnteFile } from "@/new/photos/types/file";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import * as Comlink from "comlink";
import {
    isInsideCity,
    isInsideLocationTag,
} from "services/locationSearchService";
import { Search } from "types/search";

export class DedicatedSearchWorker {
    private files: EnteFile[] = [];

    setFiles(files: EnteFile[]) {
        this.files = files;
    }

    search(search: Search) {
        return this.files.filter((file) => {
            return isSearchedFile(file, search);
        });
    }
}

Comlink.expose(DedicatedSearchWorker, self);

function isSearchedFile(file: EnteFile, search: Search) {
    if (search?.collection) {
        return search.collection === file.collectionID;
    }

    if (search?.date) {
        return isDateComponentsMatch(
            search.date,
            getUICreationDate(file, getPublicMagicMetadataSync(file)),
        );
    }
    if (search?.location) {
        return isInsideLocationTag(
            {
                latitude: file.metadata.latitude,
                longitude: file.metadata.longitude,
            },
            search.location,
        );
    }
    if (search?.city) {
        return isInsideCity(
            {
                latitude: file.metadata.latitude,
                longitude: file.metadata.longitude,
            },
            search.city,
        );
    }
    if (search?.files) {
        return search.files.indexOf(file.id) !== -1;
    }
    if (search?.person) {
        return search.person.files.indexOf(file.id) !== -1;
    }
    if (typeof search?.fileType !== "undefined") {
        return search.fileType === file.metadata.fileType;
    }
    if (typeof search?.clip !== "undefined") {
        return search.clip.has(file.id);
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
