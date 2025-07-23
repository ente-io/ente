import {
    hlsGenerationStatusSnapshot,
    hlsGenerationStatusSubscribe,
} from "ente-gallery/services/video";
import { useSyncExternalStore } from "react";
import {
    mlStatusSnapshot,
    mlStatusSubscribe,
    peopleStateSnapshot,
    peopleStateSubscribe,
} from "../../services/ml";
import { settingsSnapshot, settingsSubscribe } from "../../services/settings";
import {
    userDetailsSnapshot,
    userDetailsSubscribe,
} from "../../services/user-details";

/**
 * A convenience hook that returns {@link settingsSnapshot}, and also
 * subscribes to updates.
 */
export const useSettingsSnapshot = () =>
    useSyncExternalStore(settingsSubscribe, settingsSnapshot);

/**
 * A convenience hook that returns {@link userDetailsSnapshot}, and also
 * subscribes to updates.
 */
export const useUserDetailsSnapshot = () =>
    useSyncExternalStore(userDetailsSubscribe, userDetailsSnapshot);

/**
 * A convenience hook that returns {@link mlStatusSnapshot}, and also subscribes
 * to updates.
 */
export const useMLStatusSnapshot = () =>
    useSyncExternalStore(mlStatusSubscribe, mlStatusSnapshot);

/**
 * A convenience hook that returns {@link peopleStateSnapshot}, and also
 * subscribes to updates.
 */
export const usePeopleStateSnapshot = () =>
    useSyncExternalStore(peopleStateSubscribe, peopleStateSnapshot);

/**
 * A convenience hook that returns {@link hlsGenerationStatusSnapshot}, and also
 * subscribes to updates.
 */
export const useHLSGenerationStatusSnapshot = () =>
    useSyncExternalStore(
        hlsGenerationStatusSubscribe,
        hlsGenerationStatusSnapshot,
    );
