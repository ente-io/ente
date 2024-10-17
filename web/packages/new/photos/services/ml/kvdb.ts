import { getKV, setKV } from "@/base/kv";
import { z } from "zod";

/** cgroupID -> clusterIDs */
const ClusterIDsByCGroupID = z.record(z.string(), z.array(z.string()));

/**
 * A record containing an array of clusters (represented by their IDs), keyed by
 * the corresponding cgroup ID.
 */
export type ClusterIDsByCGroupID = z.infer<typeof ClusterIDsByCGroupID>;

/**
 * Return the list of locally persisted clusters that the user has rejected as
 * not belonging to a particular person.
 *
 * [Note: Persistent KV pairs related to ML]
 *
 * Conceptually, these could be part of ML DB. Practically, that'd would require
 * us to create a "kv" store within the ML DB, which seems both unnecessary, and
 * also potentially problematic since we'll have to introduce a version
 * migration (IndexedDB is finicky, and we've had better luck not poking it when
 * possible. See [Note: Avoiding IndexedDB flakiness by avoiding indexes]).
 */
export const savedRejectedClusters = async (): Promise<ClusterIDsByCGroupID> =>
    ClusterIDsByCGroupID.parse((await getKV("rejectedClusters")) ?? {});

/**
 * Update the locally persisted record of rejected clusters.
 *
 * Sibling of {@link savedRejectedClusters}.
 */
export const saveRejectedClusters = (entries: ClusterIDsByCGroupID[]) =>
    setKV("rejectedClusters", entries);
