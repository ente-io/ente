import { getKV, setKV } from "ente-base/kv";
import { z } from "zod/v4";

/**
 * Zod schema for {@link ClusterIDsByCGroupID}.
 */
const ClusterIDsByCGroupID = z.record(z.string(), z.array(z.string()));

/**
 * cgroupID -> clusterIDs
 *
 * A record containing an array of clusters (represented by their IDs), keyed by
 * the corresponding cgroup ID.
 */
export type ClusterIDsByCGroupID = z.infer<typeof ClusterIDsByCGroupID>;

/**
 * Return the locally persisted record of clusters per cgroup that the user has
 * rejected as not belonging to that cgroup.
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
export const saveRejectedClusters = (entries: ClusterIDsByCGroupID) =>
    setKV("rejectedClusters", entries);

/**
 * Return the list of locally persisted clusters that the user has rejected as
 * not belonging to a particular cgroup (as identified by its {@link cgroupID}).
 */
export const savedRejectedClustersForCGroup = async (
    cgroupID: string,
): Promise<string[]> =>
    savedRejectedClusters().then((cs) => cs[cgroupID] ?? []);

/**
 * Update the locally persisted record of rejected clusters for the given cgroup
 * (as identified by its {@link cgroupID}).
 */
export const saveRejectedClustersForCGroup = async (
    cgroupID: string,
    clusterIDs: string[],
) => {
    const rejectedClusters = await savedRejectedClusters();
    rejectedClusters[cgroupID] = clusterIDs;
    return saveRejectedClusters(rejectedClusters);
};
