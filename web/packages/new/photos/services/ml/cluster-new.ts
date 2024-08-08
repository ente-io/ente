import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import type { FaceIndex } from "./face";
import { dotProduct } from "./math";

/**
 * A cluster is an set of faces.
 *
 * Each cluster has an id so that a Person (a set of clusters) can refer to it.
 */
export interface Cluster {
    /**
     * A randomly generated ID to uniquely identify this cluster.
     */
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
 *
 * For ease of transportation, the Person entity on remote looks like
 *
 *     { name, clusters: { cluster_id, face_ids }}
 *
 * That is, it has the clusters embedded within itself.
 */
export interface Person {
    /**
     * A randomly generated ID to uniquely identify this person.
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
 * 2.  For each face, find its nearest neighbour in the embedding space. If no
 *     such neighbour is found within our threshold, create a new cluster.
 * 3.  Otherwise assign this face to the same cluster as its nearest neighbour.
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
export const clusterFaces = (faceIndices: FaceIndex[]) => {
    const t = Date.now();

    const faces = [...faceIDAndEmbeddings(faceIndices)];

    const clusters: Cluster[] = [];
    const clusterIndexByFaceID = new Map<string, number>();
    for (const [i, fi] of faces.entries()) {
        let j = i + 1;
        for (; j < faces.length; j++) {
            // Can't find a better way for avoiding the null assertion.
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            const fj = faces[j]!;

            // TODO-ML: The distance metric and the thresholds are placeholders.

            // The vectors are already normalized, so we can directly use their
            // dot product as their cosine similarity.
            const csim = dotProduct(fi.embedding, fj.embedding);
            if (csim > 0.5) {
                // Found a neighbour near enough. Add this face to the
                // neighbour's cluster and call it a day.
                const ci = ensure(clusterIndexByFaceID.get(fj.faceID));
                clusters[ci]?.faceIDs.push(fi.faceID);
                clusterIndexByFaceID.set(fi.faceID, ci);
                break;
            }
        }
        if (j == faces.length) {
            // We didn't find a neighbour. Create a new cluster with this face.
            const cluster = {
                id: newNonSecureID("cluster_"),
                faceIDs: [fi.faceID],
            };
            clusters.push(cluster);
            clusterIndexByFaceID.set(fi.faceID, clusters.length);
        }
    }

    log.debug(() => ["ml/cluster", { faces, clusters, clusterIndexByFaceID }]);
    log.debug(
        () =>
            `Clustered ${faces.length} faces into ${clusters.length} clusters (${Date.now() - t} ms)`,
    );

    return undefined;
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
