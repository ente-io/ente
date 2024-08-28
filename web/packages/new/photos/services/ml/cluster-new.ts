import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { clusterGroups, faceClusters } from "./db";
import type { Face, FaceIndex } from "./face";
import { dotProduct } from "./math";

/**
 * A face cluster is an set of faces.
 *
 * Each cluster has an id so that a {@link CGroup} can refer to it.
 *
 * The cluster is not directly synced to remote. Only clusters that the user
 * interacts with get synced to remote, as part of a {@link CGroup}.
 */
export interface FaceCluster {
    /**
     * A nanoid for this cluster.
     */
    id: string;
    /**
     * An unordered set of ids of the faces that belong to this cluster.
     *
     * For ergonomics of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    faceIDs: string[];
}

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
 * Cluster faces into groups.
 *
 * [Note: Face clustering algorithm]
 *
 * A cgroup (cluster group) consists of clusters, each of which itself is a set
 * of faces.
 *
 *     cgroup << cluster << face
 *
 * The clusters are generated locally by clients using the following algorithm:
 *
 * 1.  clusters = [] initially, or fetched from remote.
 *
 * 2.  For each face, find its nearest neighbour in the embedding space.
 *
 * 3.  If no such neighbour is found within our threshold, create a new cluster.
 *
 * 4.  Otherwise assign this face to the same cluster as its nearest neighbour.
 *
 * This user can then tweak the output of the algorithm by performing the
 * following actions to the list of clusters that they can see:
 *
 * -   They can provide a name for a cluster ("name a person"). This upgrades a
 *     cluster into a "cgroup", which is an entity that gets synced via remote
 *     to the user's other clients.
 *
 * -   They can attach more clusters to a cgroup ("merge clusters")
 *
 * -   They can remove a cluster from a cgroup ("break clusters").
 *
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
export const clusterFaces = async (faceIndexes: FaceIndex[]) => {
    const t = Date.now();

    // A flattened array of faces.
    const faces = [...enumerateFaces(faceIndexes)];

    // Start with the clusters we already have (either from a previous indexing,
    // or fetched from remote).
    const clusters = await faceClusters();

    // For fast reverse lookup - map from cluster ids to their index in the
    // clusters array.
    const clusterIndexForClusterID = new Map(clusters.map((c, i) => [c.id, i]));

    // For fast reverse lookup - map from face ids to the id of the cluster to
    // which they belong.
    const clusterIDForFaceID = new Map(
        clusters.flatMap((c) => c.faceIDs.map((id) => [id, c.id] as const)),
    );

    // A function to generate new cluster IDs.
    const newClusterID = () => newNonSecureID("cluster_");

    // For each face,
    for (const [i, { faceID, embedding }] of faces.entries()) {
        // If the face is already part of a cluster, then skip it.
        if (clusterIDForFaceID.get(faceID)) continue;

        // Find the nearest neighbour from among all the other faces.
        let nn: Face | undefined;
        let nnCosineSimilarity = 0;
        for (let j = 0; j < faces.length; j++) {
            // ! This is an O(n^2) loop, be careful when adding more code here.

            // Skip ourselves.
            if (i == j) continue;

            // Can't find a way of avoiding the null assertion here.
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const n = faces[j]!;

            // The vectors are already normalized, so we can directly use their
            // dot product as their cosine similarity.
            const csim = dotProduct(embedding, n.embedding);
            if (csim > 0.76 && csim > nnCosineSimilarity) {
                nn = n;
                nnCosineSimilarity = csim;
            }
        }

        if (nn) {
            // Found a neighbour near enough.

            // Find the cluster the nearest neighbour belongs to, if any.
            const nnClusterID = clusterIDForFaceID.get(nn.faceID);

            if (nnClusterID) {
                // If the neighbour is already part of a cluster, also add
                // ourselves to that cluster.

                const nnClusterIndex = ensure(
                    clusterIndexForClusterID.get(nnClusterID),
                );
                clusters[nnClusterIndex]?.faceIDs.push(faceID);
                clusterIDForFaceID.set(faceID, nnClusterID);
            } else {
                // Otherwise create a new cluster with us and our nearest
                // neighbour.

                const cluster = {
                    id: newClusterID(),
                    faceIDs: [faceID, nn.faceID],
                };
                clusterIndexForClusterID.set(cluster.id, clusters.length);
                clusterIDForFaceID.set(faceID, cluster.id);
                clusterIDForFaceID.set(nn.faceID, cluster.id);
                clusters.push(cluster);
            }
        } else {
            // We didn't find a neighbour within the threshold. Create a new
            // cluster with only this face.

            const cluster = { id: newClusterID(), faceIDs: [faceID] };
            clusterIndexForClusterID.set(cluster.id, clusters.length);
            clusterIDForFaceID.set(faceID, cluster.id);
            clusters.push(cluster);
        }
    }

    // Prune too small clusters.
    const validClusters = clusters.filter(({ faceIDs }) => faceIDs.length > 1);

    let cgroups = await clusterGroups();

    // TODO-Cluster - Currently we're not syncing with remote or saving anything
    // locally, so cgroups will be empty. Create a temporary (unsaved, unsynced)
    // cgroup, one per cluster.
    cgroups = cgroups.concat(
        validClusters.map((c) => ({
            id: c.id,
            name: undefined,
            clusterIDs: [c.id],
            isHidden: false,
            avatarFaceID: undefined,
            displayFaceID: undefined,
        })),
    );

    // For each cluster group, use the highest scoring face in any of its
    // clusters as its display face.
    const faceForFaceID = new Map(faces.map((f) => [f.faceID, f]));
    for (const cgroup of cgroups) {
        cgroup.displayFaceID = cgroup.clusterIDs
            .map((clusterID) => clusterIndexForClusterID.get(clusterID))
            .filter((i) => i !== undefined) /* 0 is a valid index */
            .flatMap((i) => clusters[i]?.faceIDs ?? [])
            .map((faceID) => faceForFaceID.get(faceID))
            .filter((face) => !!face)
            .reduce((max, face) =>
                max.score > face.score ? max : face,
            ).faceID;
    }

    log.info("ml/cluster", {
        faces,
        validClusters,
        clusterIndexForClusterID: Object.fromEntries(clusterIndexForClusterID),
        clusterIDForFaceID: Object.fromEntries(clusterIDForFaceID),
        cgroups,
    });
    log.info(
        `Clustered ${faces.length} faces into ${validClusters.length} clusters (${Date.now() - t} ms)`,
    );

    return { faces, clusters: validClusters, cgroups };
};

/**
 * A generator function that returns a stream of {faceID, embedding} values,
 * flattening all the the faces present in the given {@link faceIndices}.
 */
function* enumerateFaces(faceIndices: FaceIndex[]) {
    for (const fi of faceIndices) {
        for (const f of fi.faces) {
            yield f;
        }
    }
}
