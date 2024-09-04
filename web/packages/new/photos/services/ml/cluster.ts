import { assertionFailed } from "@/base/assert";
import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import { faceDirection, type Face, type FaceIndex } from "./face";
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
    minBlur: number;
    minScore: number;
    minClusterSize: number;
    joinThreshold: number;
    earlyExitThreshold: number;
    batchSize: number;
    offsetIncrement: number;
    badFaceHeuristics: boolean;
}

export interface ClusteringProgress {
    completed: number;
    total: number;
}

export type OnClusteringProgress = (progress: ClusteringProgress) => void;

/** A {@link Face} annotated with data needed during clustering. */
export type ClusterFace = Omit<Face, "embedding"> & {
    embedding: Float32Array;
    isBadFace: boolean;
};

export interface ClusterPreview {
    clusterSize: number;
    faces: ClusterPreviewFace[];
}

export interface ClusterPreviewFace {
    face: ClusterFace;
    cosineSimilarity: number;
    wasMerged: boolean;
}

/**
 * Cluster faces into groups.
 *
 * A cgroup (cluster group) consists of clusters, each of which itself is a set
 * of faces.
 *
 *     cgroup << cluster << face
 *
 * This function generates clusters locally using a batched form of linear
 * clustering, with a bit of lookback (and a dollop of heuristics) to get the
 * clusters to merge across batches.
 *
 * This user can later tweak these clusters by performing the following actions
 * to the list of clusters that they can see:
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
    localFiles: EnteFile[],
    opts: ClusteringOpts,
    onProgress: OnClusteringProgress,
) => {
    const {
        minBlur,
        minScore,
        minClusterSize,
        joinThreshold,
        earlyExitThreshold,
        batchSize,
        offsetIncrement,
        badFaceHeuristics,
    } = opts;
    const t = Date.now();

    const localFileByID = new Map(localFiles.map((f) => [f.id, f]));

    // A flattened array of filtered and annotated faces.
    const filteredFaces = [...enumerateFaces(faceIndexes, minBlur, minScore)];

    const fileForFaceID = new Map(
        filteredFaces.map(({ faceID }) => [
            faceID,
            ensure(localFileByID.get(ensure(fileIDFromFaceID(faceID)))),
        ]),
    );

    const fileForFace = ({ faceID }: { faceID: string }) =>
        ensure(fileForFaceID.get(faceID));

    // Sort faces temporally (a heuristic for better clusters), with the newest
    // ones first.
    const faces = filteredFaces.sort(
        (a, b) =>
            fileForFace(b).metadata.creationTime -
            fileForFace(a).metadata.creationTime,
    );

    // For fast reverse lookup - map from face ids to the face.
    const faceForFaceID = new Map(faces.map((f) => [f.faceID, f]));

    // For fast reverse lookup - map from the id of a face to the id of the
    // cluster to which it belongs.
    let clusterIDForFaceID = new Map<string, string>();

    // For fast reverse lookup - map from the id of a cluster to its position in
    // the clusters array.
    let clusterIndexForFaceID = new Map<string, number>();

    // The resultant clusters.
    // TODO-Cluster Later on, instead of starting from a blank slate, this will
    // be list of existing clusters we fetch from remote.
    let clusters: FaceCluster[] = [];

    // Process the faces in batches, but keep an overlap between batches to
    // allow "links" to form with existing clusters.
    for (let offset = 0; offset < faces.length; offset += offsetIncrement) {
        const it = Date.now();

        const batch = faces.slice(offset, offset + batchSize);
        log.info(`[batch] processing ${offset} to ${offset + batch.length}`);

        const oldState = {
            clusterIDForFaceID,
            clusterIndexForFaceID,
            clusters,
        };

        const newState = clusterBatchLinear(
            batch,
            oldState,
            joinThreshold,
            earlyExitThreshold,
            badFaceHeuristics,
            ({ completed }: ClusteringProgress) =>
                onProgress({
                    completed: offset + completed,
                    total: faces.length,
                }),
        );

        clusterIDForFaceID = newState.clusterIDForFaceID;
        clusterIndexForFaceID = newState.clusterIndexForFaceID;
        clusters = newState.clusters;

        log.info(
            `[batch] ${newState.clusters.length} clusters from ${batch.length} faces (${Date.now() - it} ms)`,
        );
    }

    // Prune clusters that are smaller than the threshold.
    const validClusters = clusters.filter(
        (cs) => cs.faceIDs.length > minClusterSize,
    );

    const sortedClusters = validClusters.sort(
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
            return { face, cosineSimilarity: csim, wasMerged: false };
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

    // TODO-Cluster the total face count is only needed during debugging
    let totalFaceCount = 0;
    for (const fi of faceIndexes) totalFaceCount += fi.faces.length;
    const filteredFaceCount = faces.length;
    const clusteredFaceCount = clusterIDForFaceID.size;
    const unclusteredFaceCount = filteredFaceCount - clusteredFaceCount;

    const unclusteredFaces = faces.filter(
        ({ faceID }) => !clusterIDForFaceID.has(faceID),
    );

    const timeTakenMs = Date.now() - t;
    log.info(
        `Clustered ${faces.length} faces into ${sortedClusters.length} clusters, ${faces.length - clusterIDForFaceID.size} faces remain unclustered (${timeTakenMs} ms)`,
    );

    return {
        totalFaceCount,
        filteredFaceCount,
        clusteredFaceCount,
        unclusteredFaceCount,
        localFileByID,
        clusterPreviews,
        clusters: sortedClusters,
        cgroups,
        unclusteredFaces: unclusteredFaces,
        timeTakenMs,
    };
};

/**
 * A generator function that returns a stream of eligible {@link ClusterFace}s
 * by flattening all the the faces present in the given {@link faceIndices}.
 *
 * During this, it also converts the embeddings to Float32Arrays to speed up the
 * dot product calculations that will happen during clustering and attaches
 * other information that the clustering algorithm needs.
 */
function* enumerateFaces(
    faceIndices: FaceIndex[],
    minBlur: number,
    minScore: number,
) {
    for (const fi of faceIndices) {
        for (const f of fi.faces) {
            if (shouldIncludeFace(f, minBlur, minScore)) {
                yield {
                    ...f,
                    embedding: new Float32Array(f.embedding),
                    isBadFace: isBadFace(f),
                };
            }
        }
    }
}

/**
 * Return true if the given face is above the minimum inclusion thresholds.
 */
const shouldIncludeFace = (face: Face, minBlur: number, minScore: number) =>
    face.blur > minBlur && face.score > minScore;

/**
 * Return true if the given face is above the minimum inclusion thresholds, but
 * is otherwise heuristically determined to be possibly spurious face detection.
 *
 * We apply a higher threshold when clustering such faces.
 */
const isBadFace = (face: Face) =>
    face.blur < 50 ||
    (face.blur < 200 && face.blur < 0.85) ||
    isSidewaysFace(face);

const isSidewaysFace = (face: Face) =>
    faceDirection(face.detection) != "straight";

/** Generate a new cluster ID. */
const newClusterID = () => newNonSecureID("cluster_");

/**
 * Extract the fileID of the {@link EnteFile} to which the face belongs from its
 * faceID.
 *
 * TODO-Cluster - duplicated with ml/index.ts
 */
const fileIDFromFaceID = (faceID: string) => {
    const fileID = parseInt(faceID.split("_")[0] ?? "");
    if (isNaN(fileID)) {
        assertionFailed(`Ignoring attempt to parse invalid faceID ${faceID}`);
        return undefined;
    }
    return fileID;
};

interface ClusteringState {
    clusterIDForFaceID: Map<string, string>;
    clusterIndexForFaceID: Map<string, number>;
    clusters: FaceCluster[];
}

const clusterBatchLinear = (
    faces: ClusterFace[],
    oldState: ClusteringState,
    joinThreshold: number,
    earlyExitThreshold: number,
    badFaceHeuristics: boolean,
    onProgress: (progress: ClusteringProgress) => void,
) => {
    const state: ClusteringState = {
        clusterIDForFaceID: new Map(oldState.clusterIDForFaceID),
        clusterIndexForFaceID: new Map(oldState.clusterIndexForFaceID),
        clusters: [...oldState.clusters],
    };

    // Sort the faces so that the already clustered ones are at the front.
    faces = faces
        .filter((f) => state.clusterIDForFaceID.has(f.faceID))
        .concat(faces.filter((f) => !state.clusterIDForFaceID.has(f.faceID)));

    // For each face in the batch
    for (const [i, fi] of faces.entries()) {
        if (i % 100 == 0) onProgress({ completed: i, total: faces.length });

        // If the face is already part of a cluster, then skip it.
        if (state.clusterIDForFaceID.has(fi.faceID)) continue;

        // Find the nearest neighbour among the previous faces in this batch.
        let nnIndex: number | undefined;
        let nnCosineSimilarity = 0;
        for (let j = i - 1; j >= 0; j--) {
            // ! This is an O(n^2) loop, be careful when adding more code here.

            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const fj = faces[j]!;

            // The vectors are already normalized, so we can directly use their
            // dot product as their cosine similarity.
            const csim = dotProduct(fi.embedding, fj.embedding);
            const threshold =
                badFaceHeuristics && fj.isBadFace ? 0.84 : joinThreshold;
            if (csim > nnCosineSimilarity && csim >= threshold) {
                nnIndex = j;
                nnCosineSimilarity = csim;

                // If we've found something "near enough", stop looking for a
                // better match (A heuristic to speed up clustering).
                if (earlyExitThreshold > 0 && csim >= earlyExitThreshold) break;
            }
        }

        if (nnIndex) {
            // Found a neighbour close enough, add ourselves to its cluster.
            const nnFace = ensure(faces[nnIndex]);
            const nnClusterIndex = ensure(
                state.clusterIndexForFaceID.get(nnFace.faceID),
            );
            const nnCluster = ensure(state.clusters[nnClusterIndex]);

            state.clusterIDForFaceID.set(fi.faceID, nnCluster.id);
            state.clusterIndexForFaceID.set(fi.faceID, nnClusterIndex);
            nnCluster.faceIDs.push(fi.faceID);
        } else {
            // No neighbour within the threshold. Create a new cluster.
            const clusterID = newClusterID();
            const clusterIndex = state.clusters.length;
            const cluster = { id: clusterID, faceIDs: [fi.faceID] };

            state.clusterIDForFaceID.set(fi.faceID, cluster.id);
            state.clusterIndexForFaceID.set(fi.faceID, clusterIndex);
            state.clusters.push(cluster);
        }
    }

    return state;
};
