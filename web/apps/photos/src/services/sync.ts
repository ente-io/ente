import { fetchAndSaveFeatureFlagsIfNeeded } from "@/new/photos/services/feature-flags";
import { triggerMLSync } from "@/new/photos/services/ml";
import { isDesktop } from "@/next/app";
import { clipService } from "services/clip-service";
import { syncCLIPEmbeddings } from "services/embeddingService";
import { syncEntities } from "services/entityService";
import { syncMapEnabled } from "services/userService";

/**
 * Perform a soft "refresh" by making various API calls to fetch state from
 * remote, using it to update our local state, and triggering periodic jobs that
 * depend on the local state.
 */
export const sync = async () => {
    // TODO: This is called after we've synced the local files DBs with remote.
    // That code belongs here, but currently that state is persisted in the top
    // level gallery React component.

    await syncEntities();
    await syncMapEnabled();
    fetchAndSaveFeatureFlagsIfNeeded();
    if (isDesktop) {
        await syncCLIPEmbeddings();
        triggerMLSync();
        void clipService.scheduleImageEmbeddingExtraction();
    }
};
