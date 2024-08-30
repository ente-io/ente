import { Hdbscan, type DebugInfo } from "hdbscan";

/**
 * Each "cluster" is a list of indexes of the embeddings belonging to that
 * particular cluster.
 */
export type EmbeddingCluster = number[];

export interface ClusterHdbscanResult {
    clusters: EmbeddingCluster[];
    noise: number[];
    debugInfo?: DebugInfo;
}

/**
 * Cluster the given {@link embeddings} using hdbscan.
 */
export const clusterHdbscan = (
    embeddings: number[][],
): ClusterHdbscanResult => {
    const hdbscan = new Hdbscan({
        input: embeddings,
        minClusterSize: 3,
        minSamples: 5,
        clusterSelectionEpsilon: 0.6,
        clusterSelectionMethod: "leaf",
        debug: false,
    });

    return {
        clusters: hdbscan.getClusters(),
        noise: hdbscan.getNoise(),
        debugInfo: hdbscan.getDebugInfo(),
    };
};
