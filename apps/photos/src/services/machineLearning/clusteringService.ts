import { DBSCAN, KMEANS, OPTICS } from "density-clustering";
import { Hdbscan } from "hdbscan";
import { HdbscanInput } from "hdbscan/dist/types";
import {
    ClusteringConfig,
    ClusteringInput,
    ClusteringMethod,
    ClusteringResults,
    HdbscanResults,
    Versioned,
} from "types/machineLearning";

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
        minPts: number = 2,
    ): ClusteringResults {
        // addLogLine("distanceFunction", DBSCAN._);
        const clusters = this.dbscan.run(dataset, epsilon, minPts);
        const noise = this.dbscan.noise;
        return { clusters, noise };
    }

    public clusterUsingOPTICS(
        dataset: Array<Array<number>>,
        epsilon: number = 1.0,
        minPts: number = 2,
    ) {
        const clusters = this.optics.run(dataset, epsilon, minPts);
        return { clusters, noise: [] };
    }

    public clusterUsingKMEANS(
        dataset: Array<Array<number>>,
        numClusters: number = 5,
    ) {
        const clusters = this.kmeans.run(dataset, numClusters);
        return { clusters, noise: [] };
    }

    public clusterUsingHdbscan(hdbscanInput: HdbscanInput): HdbscanResults {
        if (hdbscanInput.input.length < 10) {
            throw Error("too few samples to run Hdbscan");
        }

        const hdbscan = new Hdbscan(hdbscanInput);
        const clusters = hdbscan.getClusters();
        const noise = hdbscan.getNoise();
        const debugInfo = hdbscan.getDebugInfo();

        return { clusters, noise, debugInfo };
    }

    public cluster(
        method: Versioned<ClusteringMethod>,
        input: ClusteringInput,
        config: ClusteringConfig,
    ) {
        if (method.value === "Hdbscan") {
            return this.clusterUsingHdbscan({
                input,
                minClusterSize: config.minClusterSize,
                debug: config.generateDebugInfo,
            });
        } else if (method.value === "Dbscan") {
            return this.clusterUsingDBSCAN(
                input,
                config.maxDistanceInsideCluster,
                config.minClusterSize,
            );
        } else {
            throw Error("Unknown clustering method: " + method.value);
        }
    }
}

export default ClusteringService;
