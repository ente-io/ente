import { openCache } from "@/next/blob-cache";
import log from "@/next/log";
import { faceAlignment } from "services/face/align";
import mlIDbStorage from "services/face/db";
import { detectFaces, getRelativeDetection } from "services/face/detect";
import { faceEmbeddings, mobileFaceNetFaceSize } from "services/face/embed";
import {
    DetectedFace,
    Face,
    MLSyncContext,
    MLSyncFileContext,
    type FaceAlignment,
} from "services/face/types";
import { imageBitmapToBlob, warpAffineFloat32List } from "utils/image";
import { detectBlur } from "../face/blur";
import { clusterFaces } from "../face/cluster";
import { getFaceCrop } from "../face/crop";
import {
    fetchImageBitmap,
    fetchImageBitmapForContext,
    getFaceId,
    getLocalFile,
} from "../face/image";

class FaceService {
    async syncFileFaceDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { newMlFile } = fileContext;
        newMlFile.faceDetectionMethod = {
            value: "YoloFace",
            version: 1,
        };
        fileContext.newDetection = true;
        const imageBitmap = await fetchImageBitmapForContext(fileContext);
        const faceDetections = await detectFaces(imageBitmap);
        // TODO: reenable faces filtering based on width
        const detectedFaces = faceDetections?.map((detection) => {
            return {
                fileId: fileContext.enteFile.id,
                detection,
            } as DetectedFace;
        });
        newMlFile.faces = detectedFaces?.map((detectedFace) => ({
            ...detectedFace,
            id: getFaceId(detectedFace, newMlFile.imageDimensions),
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        log.info("[MLService] Detected Faces: ", newMlFile.faces?.length);
    }

    async syncFileFaceCrops(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { newMlFile } = fileContext;
        const imageBitmap = await fetchImageBitmapForContext(fileContext);
        newMlFile.faceCropMethod = {
            value: "ArcFace",
            version: 1,
        };

        for (const face of newMlFile.faces) {
            await this.saveFaceCrop(imageBitmap, face);
        }
    }

    async syncFileFaceAlignments(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ): Promise<Float32Array> {
        const { newMlFile } = fileContext;
        newMlFile.faceAlignmentMethod = {
            value: "ArcFace",
            version: 1,
        };
        fileContext.newAlignment = true;
        const imageBitmap =
            fileContext.imageBitmap ||
            (await fetchImageBitmapForContext(fileContext));

        // Execute the face alignment calculations
        for (const face of newMlFile.faces) {
            face.alignment = faceAlignment(face.detection);
        }
        // Extract face images and convert to Float32Array
        const faceAlignments = newMlFile.faces.map((f) => f.alignment);
        const faceImages = await extractFaceImagesToFloat32(
            faceAlignments,
            mobileFaceNetFaceSize,
            imageBitmap,
        );
        const blurValues = detectBlur(faceImages, newMlFile.faces);
        newMlFile.faces.forEach((f, i) => (f.blurValue = blurValues[i]));

        imageBitmap.close();
        log.info("[MLService] alignedFaces: ", newMlFile.faces?.length);

        return faceImages;
    }

    async syncFileFaceEmbeddings(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
        alignedFacesInput: Float32Array,
    ) {
        const { newMlFile } = fileContext;
        newMlFile.faceEmbeddingMethod = {
            value: "MobileFaceNet",
            version: 2,
        };
        // TODO: when not storing face crops, image will be needed to extract faces
        // fileContext.imageBitmap ||
        //     (await this.getImageBitmap(fileContext));

        const embeddings = await faceEmbeddings(alignedFacesInput);
        newMlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

        log.info("[MLService] facesWithEmbeddings: ", newMlFile.faces.length);
    }

    async syncFileFaceMakeRelativeDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { newMlFile } = fileContext;
        for (let i = 0; i < newMlFile.faces.length; i++) {
            const face = newMlFile.faces[i];
            if (face.detection.box.x + face.detection.box.width < 2) continue; // Skip if somehow already relative
            face.detection = getRelativeDetection(
                face.detection,
                newMlFile.imageDimensions,
            );
        }
    }

    async saveFaceCrop(imageBitmap: ImageBitmap, face: Face) {
        const faceCrop = getFaceCrop(imageBitmap, face.detection);

        const blob = await imageBitmapToBlob(faceCrop.image);

        const cache = await openCache("face-crops");
        await cache.put(face.id, blob);

        faceCrop.image.close();

        return blob;
    }

    async getAllSyncedFacesMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedFacesMap) {
            return syncContext.allSyncedFacesMap;
        }

        syncContext.allSyncedFacesMap = await mlIDbStorage.getAllFacesMap();
        return syncContext.allSyncedFacesMap;
    }

    public async runFaceClustering(
        syncContext: MLSyncContext,
        allFaces: Array<Face>,
    ) {
        // await this.init();

        if (!allFaces || allFaces.length < 50) {
            log.info(
                `Skipping clustering since number of faces (${allFaces.length}) is less than the clustering threshold (50)`,
            );
            return;
        }

        log.info("Running clustering allFaces: ", allFaces.length);
        syncContext.mlLibraryData.faceClusteringResults = await clusterFaces(
            allFaces.map((f) => Array.from(f.embedding)),
        );
        syncContext.mlLibraryData.faceClusteringMethod = {
            value: "Hdbscan",
            version: 1,
        };
        log.info(
            "[MLService] Got face clustering results: ",
            JSON.stringify(syncContext.mlLibraryData.faceClusteringResults),
        );

        // syncContext.faceClustersWithNoise = {
        //     clusters: syncContext.faceClusteringResults.clusters.map(
        //         (faces) => ({
        //             faces,
        //         })
        //     ),
        //     noise: syncContext.faceClusteringResults.noise,
        // };
    }

    public async regenerateFaceCrop(faceID: string) {
        const fileID = Number(faceID.split("-")[0]);
        const personFace = await mlIDbStorage.getFace(fileID, faceID);
        if (!personFace) {
            throw Error("Face not found");
        }

        const file = await getLocalFile(personFace.fileId);
        const imageBitmap = await fetchImageBitmap(file);
        return await this.saveFaceCrop(imageBitmap, personFace);
    }
}

export default new FaceService();

async function extractFaceImagesToFloat32(
    faceAlignments: Array<FaceAlignment>,
    faceSize: number,
    image: ImageBitmap,
): Promise<Float32Array> {
    const faceData = new Float32Array(
        faceAlignments.length * faceSize * faceSize * 3,
    );
    for (let i = 0; i < faceAlignments.length; i++) {
        const alignedFace = faceAlignments[i];
        const faceDataOffset = i * faceSize * faceSize * 3;
        warpAffineFloat32List(
            image,
            alignedFace,
            faceSize,
            faceData,
            faceDataOffset,
        );
    }
    return faceData;
}
