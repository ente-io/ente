/**
 * A cgroup ("cluster group") is a group of clusters (possibly containing a
 * single cluster) that the user has interacted with.
 *
 * Interactions include hiding, merging and giving a name and/or a cover photo.
 *
 * The most frequent interaction is naming a {@link FaceCluster}, which promotes
 * it to a become a {@link CGroup}. The promotion comes with the ability to be
 * synced with remote (as a "cgroup" user entity).
 *
 * There after, the user may attach more clusters to the same {@link CGroup}.
 *
 * > A named cluster group can be thought of as a "person", though this is not
 * > necessarily an accurate characterization. e.g. there can be a named cluster
 * > group that contains face clusters of pets.
 *
 * The other form of interaction is hiding. The user may hide a single (unnamed)
 * cluster, or they may hide an named {@link CGroup}. In both cases, we promote
 * the cluster to a CGroup if needed so that their request to hide gets synced.
 *
 * While in our local representation we separately maintain clusters and link to
 * them from within CGroups by their clusterID, in the remote representation
 * clusters themselves don't get synced. Instead, the "cgroup" entities synced
 * with remote contain the clusters within themselves. So a group that gets
 * synced with remote looks something like:
 *
 *     { id, name, clusters: [{ clusterID, faceIDs }] }
 *
 */
export interface CGroup {
    /**
     * A nanoid for this cluster group.
     *
     * This is the ID of the "cgroup" user entity (the envelope), and it is not
     * contained as part of the group entity payload itself.
     */
    id: string;
    /**
     * A name assigned by the user to this cluster group.
     *
     * The client should handle both empty strings and undefined as indicating a
     * cgroup without a name. When the client needs to set this to an "empty"
     * value, which happens when hiding an unnamed cluster, it should it to an
     * empty string. That is, expect `"" | undefined`, but set `""`.
     */
    name: string | undefined;
    /**
     * An unordered set of ids of the clusters that belong to this group.
     *
     * For ergonomics of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    clusterIDs: string[];
    /**
     * True if this cluster group should be hidden.
     *
     * The user can hide both named cluster groups and single unnamed clusters.
     * If the user hides a single cluster that was offered as a suggestion to
     * them on a client, the client will create a new unnamed cgroup containing
     * it, and set its hidden flag to sync it with remote (so that other clients
     * can also stop showing this cluster).
     */
    isHidden: boolean;
    /**
     * The ID of the face that should be used as the cover photo for this
     * cluster group (if the user has set one).
     *
     * This is similar to the [@link displayFaceID}, the difference being:
     *
     * -   {@link avatarFaceID} is the face selected by the user.
     *
     * -   {@link displayFaceID} is the automatic placeholder, and only comes
     *     into effect if the user has not explicitly selected a face.
     */
    avatarFaceID: string | undefined;
    /**
     * Locally determined ID of the "best" face that should be used as the
     * display face, to represent this cluster group in the UI.
     *
     * This property is not synced with remote. For more details, see
     * {@link avatarFaceID}.
     */
    displayFaceID: string | undefined;
}

/**
 * Syncronize the user's cluster groups with remote, running local clustering if
 * needed.
 *
 * A cgroup (cluster group) consists of clusters, each of which itself is a set
 * of faces.
 *
 *     cgroup << cluster << face
 *
 * CGroups are synced with remote, while clusters are a local only (though the
 * clusters that are part of a cgroup do get synced with remote).
 *
 * Clusters are generated locally using {@link clusterFaces} function. These
 * generated clusters are then mapped to cgroups based on various user actions:
 *
 * -   The user can provide a name for a cluster ("name a person"). This
 *     upgrades a cluster into a cgroup, and it then gets synced via remote to
 *     the user's other clients.
 *
 * -   They can attach more clusters to a cgroup ("merge clusters").
 *
 * -   They can remove a cluster from a cgroup ("break clusters").
 *
 * -   They can hide a cluster. This creates an unnamed cgroup so that the
 *     user's other clients know not to show it.
 */
export const syncCGroups = () => {
    // 1. Fetch existing cgroups for the user from remote.
    // 2. Save them to DB.
    // 3. Prune stale faceIDs from the clusters in the DB.
    // 4. Rerun clustering using the cgroups and clusters in DB.
    // 5. Save the generated clusters to DB.
    //
    // The user can see both the cgroups and clusters in the UI, but only the
    // cgroups are synced.
    // const syncCGroupsWithRemote()
    /*
     * After clustering, we also do some routine cleanup. Faces belonging to files
     * that have been deleted (including those in Trash) should be pruned off.
     *
     * We should not make strict assumptions about the clusters we get from remote.
     * In particular, the same face ID can be in different clusters. In such cases
     * we should assign it arbitrarily assign it to the last cluster we find it in.
     * Such leeway is intentionally provided to allow clients some slack in how they
     * implement the sync without needing to make an blocking API request for every
     * user interaction.
     */
};
