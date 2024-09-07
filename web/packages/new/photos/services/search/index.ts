import { masterKeyFromSession } from "@/base/session-store";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import i18n, { t } from "i18next";
import type { EnteFile } from "../../types/file";
import type { DateSearchResult, SearchQuery } from "./types";
import type { SearchWorker } from "./worker";

/**
 * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
 */
let _comlinkWorker: ComlinkWorker<typeof SearchWorker> | undefined;

/**
 * Lazily created, cached, instance of {@link SearchWorker}.
 */
const worker = () => (_comlinkWorker ??= createComlinkWorker()).remote;

/**
 * Create a new instance of a comlink worker that wraps a {@link SearchWorker}
 * web worker.
 */
const createComlinkWorker = () =>
    new ComlinkWorker<typeof SearchWorker>(
        "search",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Fetch any data that would be needed if the user were to search.
 */
export const triggerSearchDataSync = () =>
    void worker().then((w) => masterKeyFromSession().then((k) => w.sync(k)));

/**
 * Set the files over which we will search.
 */
export const setSearchableFiles = (enteFiles: EnteFile[]) =>
    void worker().then((w) => w.setEnteFiles(enteFiles));

/**
 * Convert a search string into a reusable "search query" that can be passed on
 * to the {@link search} function.
 *
 * @param searchString The string we want to search for.
 */
export const createSearchQuery = (searchString: string) =>
    worker().then((w) =>
        w.createSearchQuery(searchString, i18n.language, holidays()),
    );

/**
 * Search for and return the list of {@link EnteFile}s that match the given
 * {@link search} query.
 */
export const search = async (search: SearchQuery) =>
    worker().then((w) => w.search(search));

/**
 * A list of holidays - their yearly dates and localized names.
 *
 * We need to keep this on the main thread since it uses the t() function for
 * localization (although I haven't tried that in a web worker, it might work
 * there too). Also, it cannot be a const since it needs to be evaluated lazily
 * for the t() to work.
 */
const holidays = (): DateSearchResult[] => [
    { components: { month: 12, day: 25 }, label: t("CHRISTMAS") },
    { components: { month: 12, day: 24 }, label: t("CHRISTMAS_EVE") },
    { components: { month: 1, day: 1 }, label: t("NEW_YEAR") },
    { components: { month: 12, day: 31 }, label: t("NEW_YEAR_EVE") },
];
