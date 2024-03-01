import { Hdbscan } from "hdbscan";
import {
    ClusteringConfig,
    ClusteringInput,
    ClusteringMethod,
    ClusteringService,
    HdbscanResults,
    Versioned,
} from "types/machineLearning";

class HdbscanClusteringService implements ClusteringService {
    public method: Versioned<ClusteringMethod>;

    constructor() {
        this.method = {
            value: "Hdbscan",
            version: 1,
        };
    }

    public async cluster(
        input: ClusteringInput,
        config: ClusteringConfig,
    ): Promise<HdbscanResults> {
        // addLogLine('Clustering input: ', input);
        const hdbscan = new Hdbscan({
            input,

            minClusterSize: config.minClusterSize,
            minSamples: config.minSamples,
            clusterSelectionEpsilon: config.clusterSelectionEpsilon,
            clusterSelectionMethod: config.clusterSelectionMethod,
            debug: config.generateDebugInfo,
        });

        return {
            clusters: hdbscan.getClusters(),
            noise: hdbscan.getNoise(),
            debugInfo: hdbscan.getDebugInfo(),
        };
    }
}

export default new HdbscanClusteringService();
