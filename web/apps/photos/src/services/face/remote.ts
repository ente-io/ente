import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { putEmbedding } from "services/embeddingService";
import type { EnteFile } from "types/file";
import type { Point } from "./types";
import type { Face, FaceDetection, MlFileData } from "./types-old";

export const putFaceEmbedding = async (
    enteFile: EnteFile,
    mlFileData: MlFileData,
) => {
    const serverMl = LocalFileMlDataToServerFileMl(mlFileData);
    log.debug(() => ({ t: "Local ML file data", mlFileData }));
    log.debug(() => ({
        t: "Uploaded ML file data",
        d: JSON.stringify(serverMl),
    }));

    const comlinkCryptoWorker = await ComlinkCryptoWorker.getInstance();
    const { file: encryptedEmbeddingData } =
        await comlinkCryptoWorker.encryptMetadata(serverMl, enteFile.key);
    await putEmbedding({
        fileID: enteFile.id,
        encryptedEmbedding: encryptedEmbeddingData.encryptedData,
        decryptionHeader: encryptedEmbeddingData.decryptionHeader,
        model: "file-ml-clip-face",
    });
};

export interface FileML extends ServerFileMl {
    updatedAt: number;
}

class ServerFileMl {
    public fileID: number;
    public height?: number;
    public width?: number;
    public faceEmbedding: ServerFaceEmbedding;

    public constructor(
        fileID: number,
        faceEmbedding: ServerFaceEmbedding,
        height?: number,
        width?: number,
    ) {
        this.fileID = fileID;
        this.height = height;
        this.width = width;
        this.faceEmbedding = faceEmbedding;
    }
}

class ServerFaceEmbedding {
    public faces: ServerFace[];
    public version: number;
    public client: string;

    public constructor(faces: ServerFace[], client: string, version: number) {
        this.faces = faces;
        this.client = client;
        this.version = version;
    }
}

class ServerFace {
    public faceID: string;
    public embedding: number[];
    public detection: ServerDetection;
    public score: number;
    public blur: number;

    public constructor(
        faceID: string,
        embedding: number[],
        detection: ServerDetection,
        score: number,
        blur: number,
    ) {
        this.faceID = faceID;
        this.embedding = embedding;
        this.detection = detection;
        this.score = score;
        this.blur = blur;
    }
}

class ServerDetection {
    public box: ServerFaceBox;
    public landmarks: Point[];

    public constructor(box: ServerFaceBox, landmarks: Point[]) {
        this.box = box;
        this.landmarks = landmarks;
    }
}

class ServerFaceBox {
    public x: number;
    public y: number;
    public width: number;
    public height: number;

    public constructor(x: number, y: number, width: number, height: number) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }
}

function LocalFileMlDataToServerFileMl(
    localFileMlData: MlFileData,
): ServerFileMl {
    if (localFileMlData.errorCount > 0) {
        return null;
    }

    const faces: ServerFace[] = [];
    for (let i = 0; i < localFileMlData.faceEmbedding.faces.length; i++) {
        const face: Face = localFileMlData.faceEmbedding.faces[i];
        const faceID = face.faceID;
        const embedding = face.embedding;
        const score = face.score;
        const blur = face.blurValue;
        const detection: FaceDetection = face.detection;
        const box = detection.box;
        const landmarks = detection.landmarks;
        const newBox = new ServerFaceBox(box.x, box.y, box.width, box.height);

        const newFaceObject = new ServerFace(
            faceID,
            Array.from(embedding),
            new ServerDetection(newBox, landmarks),
            score,
            blur,
        );
        faces.push(newFaceObject);
    }
    const faceEmbedding = new ServerFaceEmbedding(
        faces,
        localFileMlData.faceEmbedding.client,
        localFileMlData.faceEmbedding.version,
    );
    return new ServerFileMl(
        localFileMlData.fileID,
        faceEmbedding,
        localFileMlData.height,
        localFileMlData.width,
    );
}
