import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { wait } from "@/utils/promise";
import type { EnteFile } from "../../types/file";
import { savedCGroupUserEntities, type CGroupUserEntity } from "../user-entity";
import { savedFaceClusters, saveFaceClusters } from "./db";
import {
    faceDirection,
    fileIDFromFaceID,
    type Face,
    type FaceIndex,
} from "./face";
import { dotProduct } from "./math";

/**
 * A face cluster is an set of faces, and a nanoid to uniquely identify it.
 *
 * // TODO-Cluster
 * A cluster may be local only, or synced to remote as part of a {@link CGroup}.
 */
export interface FaceCluster {
    /**
     * A nanoid for this cluster.
     */
    id: string;
    /**
     * An unordered set of ids of the faces that belong to this cluster.
     *
     * For ease of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    faces: string[];
}

export interface ClusteringProgress {
    completed: number;
    total: number;
}

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
 * Generates clusters from the given faces using a batched form of linear
 * clustering, with a bit of lookback (and a dollop of heuristics) to get the
 * clusters to merge across batches.
 *
 * The same logic is used for both the inital clustering and subsequent
 * incremental updates, just that the incremental updates will be much faster
 * since most of the files will be skipped (as they already have a cluster
 * assigned to them).
 *
 * [Note: Draining the event loop during clustering]
 *
 * The clustering is a synchronous operation, but we make it async to
 * artificially drain the worker's event loop after each mini-batch so that
 * other interactions with the worker (where this code runs) do not get stalled
 * while clustering is in progress.
 */
export const clusterFaces = async (
    faceIndexes: FaceIndex[],
    localFiles: EnteFile[],
    onProgress: (progress: ClusteringProgress) => void,
) => {
    const t = Date.now();

    const localFileByID = new Map(localFiles.map((f) => [f.id, f]));

    // A flattened array of filtered and annotated faces.
    const filteredFaces = [...enumerateFaces(faceIndexes)];

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

    // The existing, and resultant, clusters.
    //
    // We start with clusters we have currently (whether from remote or from a
    // previous local run, but preferring the remote ones). This function is
    // called after we have already synced cgroups with remote, so we know that
    // it is up to date.

    let clusters: FaceCluster[] = [];

    // Get the locally available remote cluster groups.
    const cgroupUserEntities = await savedCGroupUserEntities();

    // Sort them so that the latest ones are first.
    //
    // This is not expected to be something that makes a functional difference
    // but is done as part of a general theme of not making strict assumptions
    // about the clusters we get from remote.
    //
    // In particular, the same face ID can be in different clusters. In such
    // cases we should assign it arbitrarily assign it to the last cluster we
    // find it in. Such leeway is intentionally provided to allow clients some
    // slack in how they implement the sync without needing to make an blocking
    // API request for every user interaction.

    const sortedCGroupUserEntities = cgroupUserEntities.sort(
        (a, b) => b.updatedAt - a.updatedAt,
    );

    // Extract the remote clusters.
    clusters = clusters.concat(
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        sortedCGroupUserEntities.map((cg) => cg.data.assigned).flat(),
    );

    // Add on the clusters we have available locally.
    clusters = clusters.concat(await savedFaceClusters());

    // For fast reverse lookup - map from the id of a face to the id of the
    // cluster to which it belongs.
    const faceIDToClusterID = new Map<string, string>();

    // For fast reverse lookup - map from the id of a face to the index of its
    // corresponding cluster in the clusters array.
    const faceIDToClusterIndex = new Map<string, number>();

    // Fill in the maps with the existing data. Since the remote clusters come
    // first, they'll be preferred over any existing local clusters for the same
    // face (as is the desired behaviour).

    for (const [i, cluster] of clusters.entries()) {
        for (const faceID of cluster.faces) {
            if (!faceIDToClusterID.has(faceID)) {
                faceIDToClusterID.set(faceID, cluster.id);
                faceIDToClusterIndex.set(faceID, i);
            }
        }
    }

    const state = {
        faceIDToClusterID,
        faceIDToClusterIndex,
        clusters,
    };

    // Process the faces in batches, but keep an overlap between batches to
    // allow "links" to form with existing clusters.

    const batchSize = 10000;
    const offsetIncrement = 7500;

    for (let offset = 0; offset < faces.length; offset += offsetIncrement) {
        const it = Date.now();

        const batch = faces.slice(offset, offset + batchSize);
        log.info(`[batch] processing ${offset} to ${offset + batch.length}`);

        await clusterBatchLinear(
            batch,
            state,
            ({ completed }: ClusteringProgress) =>
                onProgress({
                    completed: offset + completed,
                    total: faces.length,
                }),
        );

        log.info(
            `[batch] ${state.clusters.length} clusters from ${batch.length} faces (${Date.now() - it} ms)`,
        );
    }

    // Prune clusters that are smaller than the threshold.
    const validClusters = clusters.filter((cs) => cs.faces.length > 2);

    const sortedClusters = validClusters.sort(
        (a, b) => b.faces.length - a.faces.length,
    );

    const clusteredFaceCount = faceIDToClusterID.size;
    const timeTakenMs = Date.now() - t;
    log.info(
        `Generated ${sortedClusters.length} clusters from ${faces.length} faces (${clusteredFaceCount} clustered ${faces.length - clusteredFaceCount} unclustered) (${timeTakenMs} ms)`,
    );

    return sortedClusters;
};

/**
 * Use the output of the clustering phase to (a) update any remote cgroups that
 * have changed, and (b) update our locally persisted clusters.
 */
export const reconcileClusters = async (clusters: FaceCluster[]) => {
    // Index clusters by their ID for fast lookup.
    const clusterByID = new Map(clusters.map((c) => [c.id, c]));

    // Get the existing remote cluster groups.
    const cgroupUserEntities = await savedCGroupUserEntities();

    // Map from clusters to their (remote) cgroup.
    const clusterIDToCGroupID = new Map<string, string>();
    for (const cgroup of cgroupUserEntities) {
        for (const cluster of cgroup.data.assigned)
            clusterIDToCGroupID.set(cluster.id, cgroup.id);
    }

    // Find the cgroups that have changed since we started.
    const changedCGroupUserEntities: CGroupUserEntity[] = [];
    for (const cgroupEntity of cgroupUserEntities) {
        for (const oldCluster of cgroupEntity.data.assigned) {
            // The clustering algorithm does not remove any existing faces, it
            // can only add new ones to the cluster. So we can use the count as
            // an indication if something changed.
            if (
                oldCluster.faces.length !=
                ensure(clusterByID.get(oldCluster.id)).faces.length
            ) {
                changedCGroupUserEntities.push({
                    ...cgroupEntity,
                    data: {
                        ...cgroupEntity.data,
                        assigned: cgroupEntity.data.assigned.map(({ id }) =>
                            ensure(clusterByID.get(id)),
                        ),
                    },
                });
                break;
            }
        }
    }

    if (changedCGroupUserEntities.length) {
        log.info(`Updating ${changedCGroupUserEntities.length} remote cgroups`);
        // TODO-Cluster do it
    }

    // Locally save clusters that are not part of a remote cgroup.
    await saveFaceClusters(
        clusters.filter(({ id }) => !clusterIDToCGroupID.has(id)),
    );
};

/**
 * A generator function that returns a stream of eligible {@link ClusterFace}s
 * by flattening all the the faces present in the given {@link faceIndices}.
 *
 * During this, it also converts the embeddings to Float32Arrays to speed up the
 * dot product calculations that will happen during clustering and attaches
 * other information that the clustering algorithm needs.
 */
function* enumerateFaces(faceIndices: FaceIndex[]) {
    for (const fi of faceIndices) {
        for (const face of fi.faces) {
            if (face.blur > 10 && face.score > 0.8) {
                yield {
                    ...face,
                    embedding: new Float32Array(face.embedding),
                    isBadFace: isBadFace(face),
                };
            }
        }
    }
}

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

interface ClusteringState {
    faceIDToClusterID: Map<string, string>;
    faceIDToClusterIndex: Map<string, number>;
    clusters: FaceCluster[];
}

const clusterBatchLinear = async (
    faces: ClusterFace[],
    state: ClusteringState,
    onProgress: (progress: ClusteringProgress) => void,
) => {
    // Sort the faces so that the already clustered ones are at the front.
    faces = faces
        .filter((f) => state.faceIDToClusterID.has(f.faceID))
        .concat(faces.filter((f) => !state.faceIDToClusterID.has(f.faceID)));

    // For each face in the batch
    for (const [i, fi] of faces.entries()) {
        if (i % 100 == 0) {
            onProgress({ completed: i, total: faces.length });
            // See: [Note: Draining the event loop during clustering]
            await wait(0);
        }

        // If the face is already part of a cluster, then skip it.
        if (state.faceIDToClusterID.has(fi.faceID)) continue;

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
            const threshold = fj.isBadFace ? 0.84 : 0.76;
            if (csim > nnCosineSimilarity && csim >= threshold) {
                nnIndex = j;
                nnCosineSimilarity = csim;

                // If we've find something above our early exit threshold, stop
                // looking for a better match (A way to speed up clustering).
                if (csim >= 0.9) break;
            }
        }

        if (nnIndex) {
            // Found a neighbour close enough, add ourselves to its cluster.
            const nnFace = ensure(faces[nnIndex]);
            const nnClusterIndex = ensure(
                state.faceIDToClusterIndex.get(nnFace.faceID),
            );
            const nnCluster = ensure(state.clusters[nnClusterIndex]);

            state.faceIDToClusterID.set(fi.faceID, nnCluster.id);
            state.faceIDToClusterIndex.set(fi.faceID, nnClusterIndex);
            nnCluster.faces.push(fi.faceID);
        } else {
            // No neighbour within the threshold. Create a new cluster.
            const clusterID = newClusterID();
            const clusterIndex = state.clusters.length;
            const cluster = { id: clusterID, faces: [fi.faceID] };

            state.faceIDToClusterID.set(fi.faceID, cluster.id);
            state.faceIDToClusterIndex.set(fi.faceID, clusterIndex);
            state.clusters.push(cluster);
        }
    }
};
