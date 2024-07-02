import { Hdbscan, type DebugInfo } from "hdbscan";

export type Cluster = number[];

export interface ClusterFacesResult {
    clusters: Cluster[];
    noise: Cluster;
    debugInfo?: DebugInfo;
}

/**
 * Cluster the given {@link faceEmbeddings}.
 *
 * @param faceEmbeddings An array of embeddings produced by our face indexing
 * pipeline. Each embedding is for a face detected in an image (a single image
 * may have multiple faces detected within it).
 */
export const clusterFaces = async (
    faceEmbeddings: Array<Array<number>>,
): Promise<ClusterFacesResult> => {
    const hdbscan = new Hdbscan({
        input: faceEmbeddings,
        minClusterSize: 3,
        minSamples: 5,
        clusterSelectionEpsilon: 0.6,
        clusterSelectionMethod: "leaf",
        debug: true,
    });

    return {
        clusters: hdbscan.getClusters(),
        noise: hdbscan.getNoise(),
        debugInfo: hdbscan.getDebugInfo(),
    };
};
