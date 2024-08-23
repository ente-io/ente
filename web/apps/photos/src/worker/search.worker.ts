import type { DateValue } from "@/new/photos/services/search/types";
import { EnteFile } from "@/new/photos/types/file";
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
        return isSameDayAnyYear(search.date)(
            new Date(file.metadata.creationTime / 1000),
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

const isSameDayAnyYear = (baseDate: DateValue) => (compareDate: Date) => {
    let same = true;

    if (baseDate.month || baseDate.month === 0) {
        same = baseDate.month === compareDate.getMonth();
    }
    if (same && baseDate.date) {
        same = baseDate.date === compareDate.getDate();
    }
    if (same && baseDate.year) {
        same = baseDate.year === compareDate.getFullYear();
    }

    return same;
};
