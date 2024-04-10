import { Face, FaceDetection, Landmark, MlFileData } from "types/machineLearning";
import { ClipEmbedding } from "types/machineLearning/data/clip";

export interface FileML extends ServerFileMl {
    updatedAt: number;
}

class ServerFileMl {
    public fileID: number;
    public height?: number;
    public width?: number;
    public faceEmbedding: ServerFaceEmbeddings;
    public clipEmbedding?: ClipEmbedding;


    public constructor(
        fileID: number,
        faceEmbedding: ServerFaceEmbeddings,
        clipEmbedding?: ClipEmbedding,
        height?: number,
        width?: number,
    ) {
        this.fileID = fileID;
        this.height = height;
        this.width = width;
        this.faceEmbedding = faceEmbedding;
        this.clipEmbedding = clipEmbedding;
    }

    toJson(): string {
        return JSON.stringify(this);
    }

    static fromJson(json: string): ServerFileMl {
        return JSON.parse(json);
    }
}

class ServerFaceEmbeddings {
    public faces: ServerFace[];
    public version: number;
    public client?: string;
    public error?: boolean;

    public constructor(
        faces: ServerFace[],
        version: number,
        client?: string,
        error?: boolean,
    ) {
        this.faces = faces;
        this.version = version;
        this.client = client;
        this.error = error;
    }

    toJson(): string {
        return JSON.stringify(this);
    }

    static fromJson(json: string): ServerFaceEmbeddings {
        return JSON.parse(json);
    }
}

class ServerFace {
    public fileID: number;
    public faceID: string;
    public embeddings: number[];
    public detection: ServerDetection;
    public score: number;
    public blur: number;
    public fileInfo?: ServerFileInfo;

    public constructor(
        fileID: number,
        faceID: string,
        embeddings: number[],
        detection: ServerDetection,
        score: number,
        blur: number,
        fileInfo?: ServerFileInfo,
    ) {
        this.fileID = fileID;
        this.faceID = faceID;
        this.embeddings = embeddings;
        this.detection = detection;
        this.score = score;
        this.blur = blur;
        this.fileInfo = fileInfo;
    }

    toJson(): string {
        return JSON.stringify(this);
    }

    static fromJson(json: string): ServerFace {
        return JSON.parse(json);
    }
}

class ServerFileInfo {
    public imageWidth?: number;
    public imageHeight?: number;

    public constructor(imageWidth?: number, imageHeight?: number) {
        this.imageWidth = imageWidth;
        this.imageHeight = imageHeight;
    }
}

class ServerDetection {
    public box: ServerFaceBox;
    public landmarks: Landmark[];

    public constructor(box: ServerFaceBox, landmarks: Landmark[]) {
        this.box = box;
        this.landmarks = landmarks;
    }

    toJson(): string {
        return JSON.stringify(this);
    }

    static fromJson(json: string): ServerDetection {
        return JSON.parse(json);
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

    toJson(): string {
        return JSON.stringify(this);
    }

    static fromJson(json: string): ServerFaceBox {
        return JSON.parse(json);
    }
}


export function LocalFileMlDataToServerFileMl(
    localFileMlData: MlFileData,
): ServerFileMl {
    if(localFileMlData.errorCount > 0 && localFileMlData.lastErrorMessage !== undefined) {
        return null
    }
    const imageDimensions = localFileMlData.imageDimensions;
    const fileInfo = new ServerFileInfo(
        imageDimensions.width,
        imageDimensions.height,
    );
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
        const newBox = new ServerFaceBox(
            box.x,
            box.y,
            box.width,
            box.height,
        );
        const newLandmarks: Landmark[] = [];
        for (let j = 0; j < landmarks.length; j++) {
            newLandmarks.push(
                 {
                    x: landmarks[j].x,
                    y: landmarks[j].y,
                 } as Landmark,
                );
        }
        
        const newFaceObject = new ServerFace(
            localFileMlData.fileId,
            faceID,
            Array.from(embedding),
            new ServerDetection(newBox, newLandmarks),
            score,
            blur,
            fileInfo,
        );
        faces.push(newFaceObject);
    }
    const faceEmbeddings = new ServerFaceEmbeddings(faces, 1,localFileMlData.lastErrorMessage);
    return new ServerFileMl(
        localFileMlData.fileId,
        faceEmbeddings,
        null,
        imageDimensions.height,
        imageDimensions.width,
    );
}


// // Not sure if this actually works
// export function ServerFileMlToLocalFileMlData(
//     serverFileMl: ServerFileMl,
// ): MlFileData {
//     const faces: Face[] = [];
//     const mlVersion: number = serverFileMl.faceEmbeddings.version;
//     const errorCount = serverFileMl.faceEmbeddings.error ? 1 : 0;
//     for (let i = 0; i < serverFileMl.faceEmbeddings.faces.length; i++) {
//         const face = serverFileMl.faceEmbeddings.faces[i];
//         if(face.detection.landmarks.length === 0) {
//             continue;
//         }
//         const detection = face.detection;
//         const box = detection.box;
//         const landmarks = detection.landmarks;
//         const newBox = new FaceBox(
//             box.xMin,
//             box.yMin,
//             box.width,
//             box.height,
//         );
//         const newLandmarks: Landmark[] = [];
//         for (let j = 0; j < landmarks.length; j++) {
//             newLandmarks.push(
//                 {
//                  x:   landmarks[j].x,
//                 y: landmarks[j].y,
//         } as Landmark
//             );
//         }
//         const newDetection = new Detection(newBox, newLandmarks);
//         const newFace = {

//         } as Face
//         faces.push(newFace);
//     }
//     return {
//         fileId: serverFileMl.fileID,
//         imageDimensions: {
//             width: serverFileMl.width,
//             height: serverFileMl.height,
//         },
//         faces,
//         mlVersion,
//         errorCount,
//     };
// }
