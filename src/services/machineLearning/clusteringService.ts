import { DBSCAN } from 'density-clustering';

class ClusteringService {
    private dbscan: DBSCAN;

    constructor() {
        this.dbscan = new DBSCAN();
    }

    public clusterUsingDBSCAN(
        dataset: Array<Array<number>>,
        epsilon: number = 1.0,
        minPts: number = 2
    ) {
        // console.log("distanceFunction", DBSCAN._);
        const clusters = this.dbscan.run(dataset, epsilon, minPts);
        const noise = this.dbscan.noise;
        return { clusters, noise };
    }
}

export default ClusteringService;
