import { useSyncExternalStore } from "react";
import {
    mlStatusSnapshot,
    mlStatusSubscribe,
    peopleStateSnapshot,
    peopleStateSubscribe,
} from "../../services/ml";

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
