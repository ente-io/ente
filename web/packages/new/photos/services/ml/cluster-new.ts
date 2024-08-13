import { newNonSecureID } from "@/base/id-worker";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { faceClusters } from "./db";
import type { FaceIndex } from "./face";
import { dotProduct } from "./math";

/**
 * A face cluster is an set of faces.
 *
 * Each cluster has an id so that a Person (a set of clusters) can refer to it.
 *
 * The cluster is not directly synced to remote. But it can indirectly get
 * synced if it gets attached to a person (which can be thought of as a named
 * cluster).
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
 * A Person is a set of clusters and some attached metadata.
 *
 * For ease of transportation, the Person entity on remote is something like
 *
 *     { name, clusters: [{ clusterID, faceIDs }] }
 *
 * That is, the Person has the clusters embedded within itself.
 */
export interface Person {
    /**
     * A nanoid for this person.
     *
     * This is the ID of the Person user entity, it is not contained as part of
     * the Person entity payload.
     */
    id: string;
    /**
     * A name assigned by the user to this person.
     */
    name: string;
    /**
     * An unordered set of ids of the clusters that belong to this person.
     *
     * For ergonomics of transportation and persistence this is an array, but it
     * should conceptually be thought of as a set.
     */
    clusterIDs: string[];
}

/**
 * Cluster faces into groups.
 *
 * [Note: Face clustering algorithm]
 *
 * A person consists of clusters, each of which itself is a set of faces.
 *
 * The clusters are generated using locally by clients using this algorithm:
 *
 * 1.  clusters = [] initially, or fetched from remote.
 *
 * 2.  For each face, find its nearest neighbour in the embedding space from
 *     amongst the faces that have already been clustered.
 *
 * 3.  If no such neighbour is found within our threshold, create a new cluster.
 *
 * 4.  Otherwise assign this face to the same cluster as its nearest neighbour.
 *
 * This user can then tweak the output of the algorithm by performing the
 * following actions to the list of clusters that they can see:
 *
 * -   They can provide a name for a cluster. This upgrades a cluster into a
 *     "Person", which then gets synced via remote to all their devices.
 *
 * -   They can attach more clusters to a person.
 *
 * -   They can remove a cluster from a person.
 */
export const clusterFaces = async (faceIndexes: FaceIndex[]) => {
    const t = Date.now();

    // The face data that we need (face ID and its embedding).
    const faces = [...faceIDAndEmbeddings(faceIndexes)];

    // Start with the clusters we already have (either from a previous indexing,
    // or fetched from remote).
    const clusters = await faceClusters();

    // For fast reverse lookup - map from cluster ids to the index in the
    // clusters array.
    const clusterIndexForClusterID = new Map(clusters.map((c, i) => [c.id, i]));

    // For fast reverse lookup - map from face ids to the id of the cluster to
    // which they belong.
    const clusterIDForFaceID = new Map(
        clusters.flatMap((c) =>
            c.faceIDs.map((faceID) => [faceID, c.id] as const),
        ),
    );

    // New cluster ID generator function.
    const newClusterID = () => newNonSecureID("cluster_");

    // For each face,
    for (const [i, { faceID, embedding }] of faces.entries()) {
        // If the face is already part of a cluster, then skip it.
        if (clusterIDForFaceID.get(faceID)) continue;

        // Find the nearest neighbour from among all the other faces.
        let nn: (typeof faces)[number] | undefined;
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
                clusters.push(cluster);
                clusterIndexForClusterID.set(cluster.id, clusters.length);
                clusterIDForFaceID.set(faceID, cluster.id);
                clusterIDForFaceID.set(nn.faceID, cluster.id);
            }
        } else {
            // We didn't find a neighbour within the threshold. Create a new
            // cluster with only this face.

            const cluster = { id: newClusterID(), faceIDs: [faceID] };
            clusters.push(cluster);
            clusterIndexForClusterID.set(cluster.id, clusters.length);
            clusterIDForFaceID.set(faceID, cluster.id);
        }
    }

    const validClusters = clusters.filter(({ faceIDs }) => faceIDs.length > 1);

    log.debug(() => [
        "ml/cluster",
        { faces, validClusters, clusterIndexForClusterID, clusterIDForFaceID },
    ]);
    log.debug(
        () =>
            `Clustered ${faces.length} faces into ${validClusters.length} clusters (${Date.now() - t} ms)`,
    );

    return validClusters;
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
