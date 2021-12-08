import { TreeNode } from 'hdbscan';
import { RawNodeDatum } from 'react-d3-tree/lib/types/common';
import { f32Average } from '.';
import { euclideanDistance } from '../../../thirdparty/face-api/euclideanDistance';
import {
    Cluster,
    ClusterFaces,
    FaceDescriptor,
    FaceWithEmbedding,
    MLSyncContext,
    NearestCluster,
} from 'types/machineLearning';

export function getClusterSummary(cluster: ClusterFaces): FaceDescriptor {
    // const faceScore = (f) => f.detection.score; // f.alignedRect.box.width *

    // return cluster
    //     .map((f) => this.allFaces[f].face)
    //     .sort((f1, f2) => faceScore(f2) - faceScore(f1))[0].descriptor;

    const descriptors = cluster.map((f) => this.allFaces[f].embedding);

    return f32Average(descriptors);
}

export function updateClusterSummaries(syncContext: MLSyncContext) {
    if (
        !syncContext.faceClusteringResults ||
        !syncContext.faceClusteringResults.clusters ||
        syncContext.faceClusteringResults.clusters.length < 1
    ) {
        return;
    }

    const resultClusters = syncContext.faceClusteringResults.clusters;

    resultClusters.forEach((resultCluster) => {
        syncContext.faceClustersWithNoise.clusters.push({
            faces: resultCluster,
            // summary: this.getClusterSummary(resultCluster),
        });
    });
}

export function getNearestCluster(
    syncContext: MLSyncContext,
    noise: FaceWithEmbedding
): NearestCluster {
    let nearest: Cluster = null;
    let nearestDist = 100000;
    syncContext.faceClustersWithNoise.clusters.forEach((c) => {
        const dist = euclideanDistance(noise.embedding, c.summary);
        if (dist < nearestDist) {
            nearestDist = dist;
            nearest = c;
        }
    });

    console.log('nearestDist: ', nearestDist);
    return { cluster: nearest, distance: nearestDist };
}

export function assignNoiseWithinLimit(syncContext: MLSyncContext) {
    if (
        !syncContext.faceClusteringResults ||
        !syncContext.faceClusteringResults.noise ||
        syncContext.faceClusteringResults.noise.length < 1
    ) {
        return;
    }

    const noise = syncContext.faceClusteringResults.noise;

    noise.forEach((n) => {
        const noiseFace = syncContext.syncedFaces[n];
        const nearest = this.getNearestCluster(syncContext, noiseFace);

        if (nearest.cluster && nearest.distance < this.maxFaceDistance) {
            console.log('Adding noise to cluser: ', n, nearest.distance);
            nearest.cluster.faces.push(n);
        } else {
            console.log(
                'No cluster for noise: ',
                n,
                'within distance: ',
                this.maxFaceDistance
            );
            this.clustersWithNoise.noise.push(n);
        }
    });
}

export function toD3Tree(treeNode: TreeNode<number>): RawNodeDatum {
    if (!treeNode.left && !treeNode.right) {
        return {
            name: treeNode.data.toString(),
            attributes: {
                face: treeNode.data,
            },
        };
    }
    const children = [];
    treeNode.left && children.push(this.toD3Tree(treeNode.left));
    treeNode.right && children.push(this.toD3Tree(treeNode.right));

    return {
        name: treeNode.data.toString(),
        children: children,
    };
}
