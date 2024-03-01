import { DBSCAN } from "density-clustering";
import {
    ClusteringConfig,
    ClusteringInput,
    ClusteringMethod,
    ClusteringService,
    HdbscanResults,
    Versioned,
} from "types/machineLearning";

class DbscanClusteringService implements ClusteringService {
    public method: Versioned<ClusteringMethod>;

    constructor() {
        this.method = {
            value: "Dbscan",
            version: 1,
        };
    }

    public async cluster(
        input: ClusteringInput,
        config: ClusteringConfig,
    ): Promise<HdbscanResults> {
        // addLogLine('Clustering input: ', input);
        const dbscan = new DBSCAN();
        const clusters = dbscan.run(
            input,
            config.clusterSelectionEpsilon,
            config.minClusterSize,
        );
        const noise = dbscan.noise;
        return { clusters, noise };
    }
}

export default new DbscanClusteringService();
