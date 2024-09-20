import { assertionFailed } from "@/base/assert";
import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import type { EnteFile } from "../../types/file";
import type { AnnotatedCGroup } from "./cgroups";
import { faceDirection, type Face, type FaceIndex } from "./face";
import { dotProduct } from "./math";

/**
 * A face cluster is an set of faces, and a nanoid to uniquely identify it.
 *
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

const clusteringOptions = {
    minBlur: 10,
    minScore: 0.8,
    minClusterSize: 2,
    joinThreshold: 0.76,
    earlyExitThreshold: 0.9,
    batchSize: 10000,
    offsetIncrement: 7500,
    badFaceHeuristics: true,
};

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
 */
export const clusterFaces = (
    faceIndexes: FaceIndex[],
    localFiles: EnteFile[],
    onProgress: (progress: ClusteringProgress) => void,
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
    } = clusteringOptions;
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
        (cs) => cs.faces.length > minClusterSize,
    );

    const sortedClusters = validClusters.sort(
        (a, b) => b.faces.length - a.faces.length,
    );

    // Convert into the data structure we're using to debug/visualize.
    const clusterPreviewClusters =
        sortedClusters.length < 60
            ? sortedClusters
            : sortedClusters.slice(0, 30).concat(sortedClusters.slice(-30));
    const clusterPreviews = clusterPreviewClusters.map((cluster) => {
        const faces = cluster.faces.map((id) => ensure(faceForFaceID.get(id)));
        const topFace = faces.reduce((top, face) =>
            top.score > face.score ? top : face,
        );
        const previewFaces: ClusterPreviewFace[] = faces.map((face) => {
            const csim = dotProduct(topFace.embedding, face.embedding);
            return { face, cosineSimilarity: csim, wasMerged: false };
        });
        return {
            clusterSize: cluster.faces.length,
            faces: previewFaces
                .sort((a, b) => b.cosineSimilarity - a.cosineSimilarity)
                .slice(0, 50),
        };
    });

    // TODO-Cluster - Currently we're not syncing with remote or saving anything
    // locally, so cgroups will be empty. Create a temporary (unsaved, unsynced)
    // cgroup, one per cluster.

    const cgroups: AnnotatedCGroup[] = [];
    for (const cluster of sortedClusters) {
        const faces = cluster.faces.map((id) => ensure(faceForFaceID.get(id)));
        const topFace = faces.reduce((top, face) =>
            top.score > face.score ? top : face,
        );
        cgroups.push({
            id: cluster.id,
            name: undefined,
            assigned: [cluster],
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
        `Generated ${sortedClusters.length} clusters from ${totalFaceCount} faces (${filteredFaceCount} filtered ${clusteredFaceCount} clustered ${unclusteredFaceCount} unclustered) (${timeTakenMs} ms)`,
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
            nnCluster.faces.push(fi.faceID);
        } else {
            // No neighbour within the threshold. Create a new cluster.
            const clusterID = newClusterID();
            const clusterIndex = state.clusters.length;
            const cluster = { id: clusterID, faces: [fi.faceID] };

            state.clusterIDForFaceID.set(fi.faceID, cluster.id);
            state.clusterIndexForFaceID.set(fi.faceID, clusterIndex);
            state.clusters.push(cluster);
        }
    }

    return state;
};
