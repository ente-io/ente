import log from "@/base/log";
import type { FaceIndex } from "./face";

/**
 * A cluster is an set of faces.
 *
 * Each cluster has an id so that a Person (a set of clusters) can refer to it.
 */
export interface Cluster {
    /** A unique nanoid to identify this cluster. */
    id: string;
    /**
     * An unordered set of ids of the faces that belong to the cluster.
     *
     * For ergonomics of transportation and persistence this is an array but it
     * should conceptually be thought of as a set.
     */
    faceIDs: string[];
}

/**
 * A Person is a set of clusters, with some attached metadata.
 *
 * The person is the user visible concept. It consists of a set of clusters,
 * each of which itself is a set of faces.
 */
export interface Person {
    /** A unique nanoid to identify this person. */
    id: string;
    /**
     * An unordered set of ids of the clusters that belong to this person.
     * For ergonomics of transportation and persistence this is an array but it
     * should conceptually be thought of as a set.
     */
    clusterIDs: string[];
}

/**
 * Cluster faces into groups.
 *
 * [Note: Face clustering algorithm]
 *
 * 1. clusters = []
 * 2. For each face, find its nearest neighbour in the embedding space. If no
 *    such neighbour is found within our threshold, create a new c
 */
export const clusterFaces = (faceIndices: FaceIndex[]) => {
    log.debug(() => ["Clustering", faceIndices]);
    return undefined;
};
