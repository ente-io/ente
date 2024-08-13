import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import type { FaceIndex } from "./face";
import { dotProduct } from "./math";

/**
 * A face cluster is an set of faces.
 *
 * Each cluster has an id so that a Person (a set of clusters) can refer to it.
 */
export interface FaceCluster {
    /**
     * A nanoid for this cluster.
     */
    id: string;
    /**
     * An unordered set of ids of the faces that belong to the cluster.
     *
     * For ergonomics of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    faceIDs: string[];
}

/**
 * A Person is a set of clusters, with some attached metadata.
 *
 * The person is the user visible concept. It consists of a set of clusters,
 * each of which itself is a set of faces.
 *
 * For ease of transportation, the Person entity on remote looks like
 *
 *     { name, clusters: [{ clusterID, faceIDs }] }
 *
 * That is, it has the clusters embedded within itself.
 */
export interface Person {
    /**
     * A nanoid for this person.
     */
    id: string;
    /**
     * An optional name assigned by the user to this person.
     */
    name: string | undefined;
    /**
     * An unordered set of ids of the clusters that belong to this person.
     *
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
 * 1.  clusters = []
 * 2.  For each face, find its nearest neighbour in the embedding space from
 *     amongst the faces that have already been clustered.
 * 3.  If no such neighbour is found within our threshold, create a new cluster.
 * 4.  Otherwise assign this face to the same cluster as its nearest neighbour.
 *
 * [Note: Face clustering feedback]
 *
 * This user can tweak the output of the algorithm by providing feedback. They
 * can perform the following actions:
 *
 * 1.  Move a cluster from one person to another.
 * 2.  Break a cluster.
 *
 */
export const clusterFaces = (faceIndexes: FaceIndex[]) => {
    const t = Date.now();

    const faces = [...faceIDAndEmbeddings(faceIndexes)];

    let clusters: FaceCluster[] = [];
    const clusterIndexByFaceID = new Map<string, number>();
    for (const [i, { faceID, embedding }] of faces.entries()) {
        // Find the nearest neighbour from among the faces we have already seen.
        let nnIndex: number | undefined;
        let nnCosineSimilarity = 0;
        for (let j = 0; j < i; j++) {
            // Can't find a way of avoiding the null assertion.
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const n = faces[j]!;

            // The vectors are already normalized, so we can directly use their
            // dot product as their cosine similarity.
            const csim = dotProduct(embedding, n.embedding);
            if (csim > 0.76 && csim > nnCosineSimilarity) {
                nnIndex = j;
                nnCosineSimilarity = csim;
            }
        }
        if (nnIndex === undefined) {
            // We didn't find a neighbour. Create a new cluster with this face.

            const cluster = {
                id: newNonSecureID("cluster_"),
                faceIDs: [faceID],
            };
            clusters.push(cluster);
            clusterIndexByFaceID.set(faceID, clusters.length);
        } else {
            // Found a neighbour near enough. Add this face to the neighbour's
            // cluster.

            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const nn = faces[nnIndex]!;
            const nnClusterIndex = ensure(clusterIndexByFaceID.get(nn.faceID));
            clusters[nnClusterIndex]?.faceIDs.push(faceID);
            clusterIndexByFaceID.set(faceID, nnClusterIndex);
        }
    }

    clusters = clusters.filter(({ faceIDs }) => faceIDs.length > 1);

    log.debug(() => ["ml/cluster", { faces, clusters, clusterIndexByFaceID }]);
    log.debug(
        () =>
            `Clustered ${faces.length} faces into ${clusters.length} clusters (${Date.now() - t} ms)`,
    );

    return clusters;
};

/**
 * A generator function that returns a stream of {faceID, embedding} values,
 * flattening all the all the faces present in the given {@link faceIndices}.
 */
function* faceIDAndEmbeddings(faceIndices: FaceIndex[]) {
    for (const fi of faceIndices) {
        for (const f of fi.faces) {
            yield { faceID: f.faceID, embedding: f.embedding };
        }
    }
}
