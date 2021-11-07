import { DBSCAN, OPTICS, KMEANS } from 'density-clustering';
import { ClusteringResults } from 'utils/machineLearning/types';
import Clustering from 'hdbscanjs';

class ClusteringService {
    private dbscan: DBSCAN;
    private optics: OPTICS;
    private kmeans: KMEANS;

    constructor() {
        this.dbscan = new DBSCAN();
        this.optics = new OPTICS();
        this.kmeans = new KMEANS();
    }

    public clusterUsingDBSCAN(
        dataset: Array<Array<number>>,
        epsilon: number = 1.0,
        minPts: number = 2
    ): ClusteringResults {
        // console.log("distanceFunction", DBSCAN._);
        const clusters = this.dbscan.run(dataset, epsilon, minPts);
        const noise = this.dbscan.noise;
        return { clusters, noise };
    }

    public clusterUsingOPTICS(
        dataset: Array<Array<number>>,
        epsilon: number = 1.0,
        minPts: number = 2
    ) {
        const clusters = this.optics.run(dataset, epsilon, minPts);
        return { clusters, noise: [] };
    }

    public clusterUsingKMEANS(
        dataset: Array<Array<number>>,
        numClusters: number = 5
    ) {
        const clusters = this.kmeans.run(dataset, numClusters);
        return { clusters, noise: [] };
    }

    public clusterUsingHDBSCAN(
        dataset: Array<Array<number>>
        // epsilon: number = 1.0,
        // minPts: number = 2
    ) {
        if (dataset.length < 1) {
            return null;
        }

        const hdataset = dataset.map((d, index) => {
            return { data: d, opt: index };
        });

        const cluster = new Clustering(hdataset, Clustering.distFunc.euclidean);
        const treeNode = cluster.getTree();
        // const allNodes = treeNode.filter(()=>true, null);
        console.log(treeNode);
        return treeNode;
    }
}

export default ClusteringService;
