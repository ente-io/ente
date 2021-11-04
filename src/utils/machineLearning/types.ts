import { NormalizedFace } from '@tensorflow-models/blazeface';

export interface MLSyncResult {
    allFaces: FaceWithEmbedding[];
}

export interface AlignedFace extends NormalizedFace {
    alignedBox: [number, number, number, number];
}

export declare type FaceEmbedding = Array<number>;

export declare type FaceImage = Array<Array<Array<number>>>;

export interface FaceWithEmbedding {
    fileId: string;
    face: AlignedFace;
    embedding: FaceEmbedding;
    faceImage: FaceImage;
}
