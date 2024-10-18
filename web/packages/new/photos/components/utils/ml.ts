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
 * A convenience hook that returns visible people array from the
 * {@link peopleSnapshot}, and also subscribes to updates.
 */
export const useVisiblePeople = () =>
    useSyncExternalStore(peopleSubscribe, peopleSnapshot)?.visiblePeople;
