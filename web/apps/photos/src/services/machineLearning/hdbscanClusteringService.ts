import { Hdbscan } from "hdbscan";
import {
    ClusteringConfig,
    ClusteringInput,
    ClusteringMethod,
    ClusteringService,
    HdbscanResults,
    Versioned,
} from "services/ml/types";

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
        // log.info('Clustering input: ', input);
        const hdbscan = new Hdbscan({
            input,

            minClusterSize: 3,
            minSamples: 5,
            clusterSelectionEpsilon: 0.6,
            clusterSelectionMethod: "leaf",
            debug: true,
        });

        return {
            clusters: hdbscan.getClusters(),
            noise: hdbscan.getNoise(),
            debugInfo: hdbscan.getDebugInfo(),
        };
    }
}

export default new HdbscanClusteringService();
