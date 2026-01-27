declare module "supercluster" {
    export type BBox = [number, number, number, number];

    export interface PointGeometry {
        type: "Point";
        coordinates: [number, number];
    }

    export interface PointFeature<
        TPointProperties = Record<string, unknown>,
    > {
        type: "Feature";
        properties: TPointProperties;
        geometry: PointGeometry;
    }

    export interface ClusterProperties {
        cluster: true;
        cluster_id: number;
        point_count: number;
        point_count_abbreviated?: number | string;
    }

    export interface ClusterFeature<
        TClusterProperties = Record<string, unknown>,
    > {
        type: "Feature";
        properties: TClusterProperties & ClusterProperties;
        geometry: PointGeometry;
    }

    export type ClusterOrPoint<
        TPointProperties = Record<string, unknown>,
        TClusterProperties = Record<string, unknown>,
    > = PointFeature<TPointProperties> | ClusterFeature<TClusterProperties>;

    export interface SuperclusterOptions<
        TPointProperties = Record<string, unknown>,
        TClusterProperties = Record<string, unknown>,
    > {
        radius?: number;
        maxZoom?: number;
        minZoom?: number;
        minPoints?: number;
        extent?: number;
        nodeSize?: number;
        log?: boolean;
        generateId?: boolean;
        map?: (props: TPointProperties) => TClusterProperties;
        reduce?: (
            accumulated: TClusterProperties,
            props: TClusterProperties,
        ) => void;
    }

    export default class Supercluster<
        TPointProperties = Record<string, unknown>,
        TClusterProperties = Record<string, unknown>,
    > {
        constructor(
            options?: SuperclusterOptions<TPointProperties, TClusterProperties>,
        );
        load(points: PointFeature<TPointProperties>[]): this;
        getClusters(
            bbox: BBox,
            zoom: number,
        ): ClusterOrPoint<TPointProperties, TClusterProperties>[];
        getChildren(
            clusterId: number,
        ): ClusterOrPoint<TPointProperties, TClusterProperties>[];
        getLeaves(
            clusterId: number,
            limit: number,
            offset: number,
        ): PointFeature<TPointProperties>[];
        getClusterExpansionZoom(clusterId: number): number;
        getTile?(
            z: number,
            x: number,
            y: number,
        ): {
            features: Array<{
                type: "Feature";
                geometry: { type: "Point"; coordinates: [number, number] };
                properties: Record<string, unknown>;
            }>;
        } | null;
    }
}
