import log from "@/base/log";
import { customAPIOrigin } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class UploadState {
    /**
     * `true` if the workers should be disabled for uploads.
     */
    shouldDisableCFUploadProxy = false;
}

/** State shared by the functions in this module. See {@link UploadState}. */
let _state = new UploadState();

/**
 * Reset any internal state maintained by the module.
 *
 * This is primarily meant as a way for stateful apps (e.g. photos) to clear any
 * user specific state on logout.
 */
export const resetUploadState = () => {
    _state = new UploadState();
};

/**
 * Return true to disable the upload of files via Cloudflare Workers.
 *
 * These workers were introduced as a way of make file uploads faster:
 * https://ente.io/blog/tech/making-uploads-faster/
 *
 * By default, that's the route we take. However, there are multiple reasons why
 * this might be disabled.
 *
 * 1. During development and when self-hosting it we disable them to directly
 *    upload to the S3-compatible URLs returned by the ente API.
 *
 * 2. In rare cases, the user might have trouble reaching Cloudflare's network
 *    from their ISP. In such cases, the user can locally turn this off via
 *    settings.
 *
 * 3. There is also the original global toggle that was added when this feature
 *    was introduced.
 *
 * This function returns the in-memory value. It is updated when #2 changes (if
 * we're running in a context where that makes sense). The #3 remote status is
 * obtained once, on app start.
 */
export const shouldDisableCFUploadProxy = () =>
    _state.shouldDisableCFUploadProxy;

/**
 * Update the in-memory value of {@link shouldDisableCFUploadProxy}.
 *
 * @param savedPreference An optional user preference that the user has
 * expressed to disable the proxy.
 */
export const updateShouldDisableCFUploadProxy = async (
    savedPreference?: boolean,
) => {
    _state.shouldDisableCFUploadProxy =
        // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
        savedPreference || (await computeShouldDisableCFUploadProxy());
};

const computeShouldDisableCFUploadProxy = async () => {
    // If a custom origin is set, that means we're not running a production
    // deployment (maybe we're running locally, or being self-hosted).
    //
    // In such cases, disable the Cloudflare upload proxy (which won't work for
    // self-hosters), and instead just directly use the upload URLs that museum
    // gives us.
    if (await customAPIOrigin()) return true;

    // See if the global flag to disable this is set.
    try {
        const res = await fetch("https://static.ente.io/feature_flags.json");
        return (
            StaticFeatureFlags.parse(await res.json()).disableCFUploadProxy ??
            false
        );
    } catch (e) {
        log.warn("Ignoring error when getting feature_flags.json", e);
        return false;
    }
};

const StaticFeatureFlags = z.object({
    disableCFUploadProxy: z.boolean().nullish().transform(nullToUndefined),
});
