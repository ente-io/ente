import {
    euclidean,
    // TreeNode
} from 'hdbscan';
// import { RawNodeDatum } from 'react-d3-tree/lib/types/common';
// import { f32Average, getAllFacesFromMap } from '.';
import {
    FacesCluster,
    // Cluster,
    // FaceDescriptor,
    FaceWithEmbedding,
    MLSyncContext,
    NearestCluster,
} from 'types/machineLearning';
import { addLogLine } from 'utils/logging';
// import { getAllFacesMap } from 'utils/storage/mlStorage';

// export function getClusterSummary(cluster: Cluster): FaceDescriptor {
// const faceScore = (f) => f.detection.score; // f.alignedRect.box.width *
// return cluster
//     .map((f) => this.allFaces[f].face)
//     .sort((f1, f2) => faceScore(f2) - faceScore(f1))[0].descriptor;
// const descriptors = cluster.map((f) => this.allFaces[f].embedding);
// return f32Average(descriptors);
// }

export function updateClusterSummaries(syncContext: MLSyncContext) {
    if (
        !syncContext.mlLibraryData?.faceClusteringResults?.clusters ||
        syncContext.mlLibraryData?.faceClusteringResults?.clusters.length < 1
    ) {
        return;
    }

    const resultClusters =
        syncContext.mlLibraryData.faceClusteringResults.clusters;

    resultClusters.forEach((resultCluster) => {
        syncContext.mlLibraryData.faceClustersWithNoise.clusters.push({
            faces: resultCluster,
            // summary: this.getClusterSummary(resultCluster),
        });
    });
}

export function getNearestCluster(
    syncContext: MLSyncContext,
    noise: FaceWithEmbedding
): NearestCluster {
    let nearest: FacesCluster = null;
    let nearestDist = 100000;
    syncContext.mlLibraryData.faceClustersWithNoise.clusters.forEach((c) => {
        const dist = euclidean(
            Array.from(noise.embedding),
            Array.from(c.summary)
        );
        if (dist < nearestDist) {
            nearestDist = dist;
            nearest = c;
        }
    });

    addLogLine('nearestDist: ', nearestDist);
    return { cluster: nearest, distance: nearestDist };
}

// export async function assignNoiseWithinLimit(syncContext: MLSyncContext) {
//     if (
//         !syncContext.mlLibraryData?.faceClusteringResults?.noise ||
//         syncContext.mlLibraryData?.faceClusteringResults.noise.length < 1
//     ) {
//         return;
//     }

//     const noise = syncContext.mlLibraryData.faceClusteringResults.noise;
//     const allFacesMap = await getAllFacesMap();
//     const allFaces = getAllFacesFromMap(allFacesMap);

//     noise.forEach((n) => {
//         const noiseFace = allFaces[n];
//         const nearest = this.getNearestCluster(syncContext, noiseFace);

//         if (nearest.cluster && nearest.distance < this.maxFaceDistance) {
//             addLogLine('Adding noise to cluser: ', n, nearest.distance);
//             nearest.cluster.faces.push(n);
//         } else {
//             addLogLine(
//                 'No cluster for noise: ',
//                 n,
//                 'within distance: ',
//                 this.maxFaceDistance
//             );
//             this.clustersWithNoise.noise.push(n);
//         }
//     });
// }

// TODO: remove recursion to avoid stack size limits
// export function toD3Tree(
//     treeNode: TreeNode<number>,
//     allObjects: Array<any>
// ): RawNodeDatum {
//     if (!treeNode.left && !treeNode.right) {
//         return {
//             name: treeNode.data.toString(),
//             attributes: {
//                 face: allObjects[treeNode.data],
//             },
//         };
//     }
//     const children = [];
//     treeNode.left && children.push(toD3Tree(treeNode.left, allObjects));
//     treeNode.right && children.push(toD3Tree(treeNode.right, allObjects));

//     return {
//         name: treeNode.data.toString(),
//         children: children,
//     };
// }
