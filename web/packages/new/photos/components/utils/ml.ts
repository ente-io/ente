import { useSyncExternalStore } from "react";
import {
    mlStatusSnapshot,
    mlStatusSubscribe,
    peopleSnapshot,
    peopleSubscribe,
} from "../../services/ml";

/**
 * A convenience hook that returns {@link mlStatusSnapshot}, subscribing to
 * updates.
 */
export const useMLStatus = () =>
    useSyncExternalStore(mlStatusSubscribe, mlStatusSnapshot);

/**
 * A convenience hook that returns {@link peopleSnapshot}, subscribing to
 * updates.
 */
export const usePeople = () =>
    useSyncExternalStore(peopleSubscribe, peopleSnapshot);
