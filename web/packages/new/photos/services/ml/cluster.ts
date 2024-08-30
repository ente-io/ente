import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { type EmbeddingCluster, clusterHdbscan } from "./cluster-hdb";
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

export interface ClusteringOpts {
    method: "linear" | "hdbscan";
    minBlur: number;
    minScore: number;
    batchSize: number;
    joinThreshold: number;
}

export interface ClusterPreview {
    clusterSize: number;
    faces: ClusterPreviewFace[];
}

export interface ClusterPreviewFace {
    face: Face;
    cosineSimilarity: number;
    wasMerged: boolean;
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
export const clusterFaces = (
    faceIndexes: FaceIndex[],
    opts: ClusteringOpts,
) => {
    const { method, batchSize, minBlur, minScore, joinThreshold } = opts;
    const t = Date.now();

    // A flattened array of faces.
    const faces = [...enumerateFaces(faceIndexes)]
        .filter((f) => f.blur > minBlur)
        .filter((f) => f.score > minScore);

    // For fast reverse lookup - map from face ids to the face.
    const faceForFaceID = new Map(faces.map((f) => [f.faceID, f]));

    const faceEmbeddings = faces.map(({ embedding }) => embedding);

    // For fast reverse lookup - map from cluster ids to their index in the
    // clusters array.
    const clusterIndexForClusterID = new Map<string, number>();

    // For fast reverse lookup - map from the id of a face to the id of the
    // cluster to which it belongs.
    const clusterIDForFaceID = new Map<string, string>();

    // Keeps track of which faces were found by the OG clustering algorithm, and
    // which were sublimated in from a later match.
    const wasMergedFaceIDs = new Set<string>();

    // A function to chain two reverse lookup.
    const firstFaceOfCluster = (cluster: FaceCluster) =>
        ensure(faceForFaceID.get(ensure(cluster.faceIDs[0])));

    // A function to generate new cluster IDs.
    const newClusterID = () => newNonSecureID("cluster_");

    // The resultant clusters.
    // TODO-Cluster Later on, instead of starting from a blank slate, this will
    // be list of existing clusters we fetch from remote.
    const clusters: FaceCluster[] = [];

    // Process the faces in batches.
    for (let i = 0; i < faceEmbeddings.length; i += batchSize) {
        const it = Date.now();

        const embeddingBatch = faceEmbeddings.slice(i, i + batchSize);
        let embeddingClusters: EmbeddingCluster[];
        if (method == "hdbscan") {
            ({ clusters: embeddingClusters } = clusterHdbscan(embeddingBatch));
        } else {
            ({ clusters: embeddingClusters } = clusterLinear(
                embeddingBatch,
                joinThreshold,
            ));
        }

        log.info(
            `${method} produced ${embeddingClusters.length} clusters from ${embeddingBatch.length} faces (${Date.now() - it} ms)`,
        );

        // Merge the new clusters we got from this batch into the existing
        // clusters if they are "near" enough (using some heuristic).
        //
        // We need to ensure we don't change any of the existing cluster IDs,
        // since these might be existing clusters we got from remote.

        // Create a copy so that we don't modify existing clusters as we're
        // iterating.
        const existingClusters = [...clusters];

        for (const newCluster of embeddingClusters) {
            // Find the existing cluster whose (arbitrarily chosen) first face
            // is the nearest neighbour of the (arbitrarily chosen) first face
            // of the cluster produced in this batch.

            const newFace = ensure(faces[i + ensure(newCluster[0])]);

            let nnCluster: FaceCluster | undefined;
            let nnCosineSimilarity = 0;
            for (const existingCluster of existingClusters) {
                const existingFace = firstFaceOfCluster(existingCluster);

                // The vectors are already normalized, so we can directly use their
                // dot product as their cosine similarity.
                const csim = dotProduct(
                    existingFace.embedding,
                    newFace.embedding,
                );

                // Use a higher cosine similarity threshold if either of the two
                // faces are blurry.
                const threshold =
                    existingFace.blur < 200 || newFace.blur < 200
                        ? 0.9
                        : joinThreshold;
                if (csim > threshold && csim > nnCosineSimilarity) {
                    nnCluster = existingCluster;
                    nnCosineSimilarity = csim;
                }
            }

            // If we found an existing cluster that is near enough, merge the
            // new cluster into the existing cluster.
            if (nnCluster) {
                for (const j of newCluster) {
                    const { faceID } = ensure(faces[i + j]);
                    wasMergedFaceIDs.add(faceID);
                    nnCluster.faceIDs.push(faceID);
                    clusterIDForFaceID.set(faceID, nnCluster.id);
                }
            } else {
                // Otherwise retain the new cluster.
                const clusterID = newClusterID();
                const faceIDs: string[] = [];
                for (const j of newCluster) {
                    const { faceID } = ensure(faces[i + j]);
                    faceIDs.push(faceID);
                    clusterIDForFaceID.set(faceID, clusterID);
                }
                clusterIndexForClusterID.set(clusterID, clusters.length);
                clusters.push({ id: clusterID, faceIDs });
            }
        }
    }

    const sortedClusters = clusters.sort(
        (a, b) => b.faceIDs.length - a.faceIDs.length,
    );

    // Convert into the data structure we're using to debug/visualize.
    const clusterPreviewClusters =
        sortedClusters.length < 60
            ? sortedClusters
            : sortedClusters.slice(0, 30).concat(sortedClusters.slice(-30));
    const clusterPreviews = clusterPreviewClusters.map((cluster) => {
        const faces = cluster.faceIDs.map((id) =>
            ensure(faceForFaceID.get(id)),
        );
        const topFace = faces.reduce((top, face) =>
            top.score > face.score ? top : face,
        );
        const previewFaces: ClusterPreviewFace[] = faces.map((face) => {
            const csim = dotProduct(topFace.embedding, face.embedding);
            const wasMerged = wasMergedFaceIDs.has(face.faceID);
            return { face, cosineSimilarity: csim, wasMerged };
        });
        return {
            clusterSize: cluster.faceIDs.length,
            faces: previewFaces
                .sort((a, b) => b.cosineSimilarity - a.cosineSimilarity)
                .slice(0, 50),
        };
    });

    // TODO-Cluster - Currently we're not syncing with remote or saving anything
    // locally, so cgroups will be empty. Create a temporary (unsaved, unsynced)
    // cgroup, one per cluster.

    const cgroups: CGroup[] = [];
    for (const cluster of sortedClusters) {
        const faces = cluster.faceIDs.map((id) =>
            ensure(faceForFaceID.get(id)),
        );
        const topFace = faces.reduce((top, face) =>
            top.score > face.score ? top : face,
        );
        cgroups.push({
            id: cluster.id,
            name: undefined,
            clusterIDs: [cluster.id],
            isHidden: false,
            avatarFaceID: undefined,
            displayFaceID: topFace.faceID,
        });
    }

    const clusteredFaceCount = clusterIDForFaceID.size;
    const unclusteredFaceCount = faces.length - clusteredFaceCount;

    const unclusteredFaces = faces.filter(
        ({ faceID }) => !clusterIDForFaceID.has(faceID),
    );

    const timeTakenMs = Date.now() - t;
    log.info(
        `Clustered ${faces.length} faces into ${clusters.length} clusters, with ${faces.length - clusterIDForFaceID.size} faces remaining unclustered (${timeTakenMs} ms)`,
    );

    return {
        clusteredFaceCount,
        unclusteredFaceCount,
        clusterPreviews,
        clusters: sortedClusters,
        cgroups,
        unclusteredFaces: unclusteredFaces,
        timeTakenMs,
    };
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

interface ClusterLinearResult {
    clusters: EmbeddingCluster[];
}

const clusterLinear = (
    embeddings: number[][],
    threshold: number,
): ClusterLinearResult => {
    const clusters: EmbeddingCluster[] = [];
    const clusterIndexForEmbeddingIndex = new Map<number, number>();
    // For each embedding
    for (const [i, ei] of embeddings.entries()) {
        // If the embedding is already part of a cluster, then skip it.
        if (clusterIndexForEmbeddingIndex.get(i)) continue;

        // Find the nearest neighbour from among all the other embeddings.
        let nnIndex: number | undefined;
        let nnCosineSimilarity = 0;
        for (const [j, ej] of embeddings.entries()) {
            // ! This is an O(n^2) loop, be careful when adding more code here.

            // Skip ourselves.
            if (i == j) continue;

            // The vectors are already normalized, so we can directly use their
            // dot product as their cosine similarity.
            const csim = dotProduct(ei, ej);
            if (csim > threshold && csim > nnCosineSimilarity) {
                nnIndex = j;
                nnCosineSimilarity = csim;
            }
        }

        if (nnIndex) {
            // Find the cluster the nearest neighbour belongs to, if any.
            const nnClusterIndex = clusterIndexForEmbeddingIndex.get(nnIndex);

            if (nnClusterIndex) {
                // If the neighbour is already part of a cluster, also add
                // ourselves to that cluster.

                ensure(clusters[nnClusterIndex]).push(i);
                clusterIndexForEmbeddingIndex.set(i, nnClusterIndex);
            } else {
                // Otherwise create a new cluster with us and our nearest
                // neighbour.

                clusterIndexForEmbeddingIndex.set(i, clusters.length);
                clusterIndexForEmbeddingIndex.set(nnIndex, clusters.length);
                clusters.push([i, nnIndex]);
            }
        } else {
            // We didn't find a neighbour within the threshold. Create a new
            // cluster with only this embedding.

            clusterIndexForEmbeddingIndex.set(i, clusters.length);
            clusters.push([i]);
        }
    }

    // Prune singleton clusters.
    const validClusters = clusters.filter((cs) => cs.length > 1);

    return { clusters: validClusters };
};
