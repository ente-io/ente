import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { putEmbedding } from "services/embeddingService";
import type { EnteFile } from "types/file";
import type { Point } from "./geom";
import type { Face, FaceDetection, MlFileData } from "./types";

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
    log.info(
        `putEmbedding embedding to server for file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
    );
    const res = await putEmbedding({
        fileID: enteFile.id,
        encryptedEmbedding: encryptedEmbeddingData.encryptedData,
        decryptionHeader: encryptedEmbeddingData.decryptionHeader,
        model: "file-ml-clip-face",
    });
    log.info("putEmbedding response: ", res);
};

export interface FileML extends ServerFileMl {
    updatedAt: number;
}

class ServerFileMl {
    public fileID: number;
    public height?: number;
    public width?: number;
    public faceEmbedding: ServerFaceEmbeddings;

    public constructor(
        fileID: number,
        faceEmbedding: ServerFaceEmbeddings,
        height?: number,
        width?: number,
    ) {
        this.fileID = fileID;
        this.height = height;
        this.width = width;
        this.faceEmbedding = faceEmbedding;
    }
}

class ServerFaceEmbeddings {
    public faces: ServerFace[];
    public version: number;
    /* TODO
    public client?: string;
    public error?: boolean;
    */

    public constructor(faces: ServerFace[], version: number) {
        this.faces = faces;
        this.version = version;
    }
}

class ServerFace {
    public faceID: string;
    // TODO-ML: singular?
    public embeddings: number[];
    public detection: ServerDetection;
    public score: number;
    public blur: number;

    public constructor(
        faceID: string,
        embeddings: number[],
        detection: ServerDetection,
        score: number,
        blur: number,
    ) {
        this.faceID = faceID;
        this.embeddings = embeddings;
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
    public xMin: number;
    public yMin: number;
    public width: number;
    public height: number;

    public constructor(
        xMin: number,
        yMin: number,
        width: number,
        height: number,
    ) {
        this.xMin = xMin;
        this.yMin = yMin;
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
    const imageDimensions = localFileMlData.imageDimensions;

    const faces: ServerFace[] = [];
    for (let i = 0; i < localFileMlData.faces.length; i++) {
        const face: Face = localFileMlData.faces[i];
        const faceID = face.id;
        const embedding = face.embedding;
        const score = face.detection.probability;
        const blur = face.blurValue;
        const detection: FaceDetection = face.detection;
        const box = detection.box;
        const landmarks = detection.landmarks;
        const newBox = new ServerFaceBox(box.x, box.y, box.width, box.height);

        // TODO-ML: Add client UA and version
        const newFaceObject = new ServerFace(
            faceID,
            Array.from(embedding),
            new ServerDetection(newBox, landmarks),
            score,
            blur,
        );
        faces.push(newFaceObject);
    }
    const faceEmbeddings = new ServerFaceEmbeddings(faces, 1);
    return new ServerFileMl(
        localFileMlData.fileId,
        faceEmbeddings,
        imageDimensions.height,
        imageDimensions.width,
    );
}
