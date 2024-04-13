import { ClipEmbedding } from "./clip";
import { Face } from "./face";

export interface FileML {
    fileID: number;
    clip?: ClipEmbedding;
    faces: Face[];
    height: number;
    width: number;
    version: number;
    error?: string;
}
