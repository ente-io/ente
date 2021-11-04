import { NormalizedFace } from '@tensorflow-models/blazeface';

export interface MLSyncResult {
    allFaces: number[][];
}

export interface AlignedFace extends NormalizedFace {
    alignedBox: [number, number, number, number];
}

export declare type FaceEmbedding = Array<number>;
