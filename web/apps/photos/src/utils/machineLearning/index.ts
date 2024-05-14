import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import log from "@/next/log";
import PQueue from "p-queue";
import DownloadManager from "services/download";
import { getLocalFiles } from "services/fileService";
import { Dimensions } from "services/ml/geom";
import {
    DetectedFace,
    Face,
    FaceAlignment,
    MlFileData,
    Person,
} from "services/ml/types";
import { EnteFile } from "types/file";
import { getRenderableImage } from "utils/file";
import { clamp, warpAffineFloat32List } from "utils/image";
import mlIDbStorage from "utils/storage/mlIDbStorage";


export async function getLocalFile(fileId: number) {
    const localFiles = await getLocalFiles();
    return localFiles.find((f) => f.id === fileId);
}

export function getFaceId(detectedFace: DetectedFace, imageDims: Dimensions) {
    const xMin = clamp(
        detectedFace.detection.box.x / imageDims.width,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const yMin = clamp(
        detectedFace.detection.box.y / imageDims.height,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const xMax = clamp(
        (detectedFace.detection.box.x + detectedFace.detection.box.width) /
            imageDims.width,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);
    const yMax = clamp(
        (detectedFace.detection.box.y + detectedFace.detection.box.height) /
            imageDims.height,
        0.0,
        0.999999,
    )
        .toFixed(5)
        .substring(2);

    const rawFaceID = `${xMin}_${yMin}_${xMax}_${yMax}`;
    const faceID = `${detectedFace.fileId}_${rawFaceID}`;

    return faceID;
}

export async function getImageBlobBitmap(blob: Blob): Promise<ImageBitmap> {
    return await createImageBitmap(blob);
}

async function getOriginalFile(file: EnteFile, queue?: PQueue) {
    let fileStream;
    if (queue) {
        fileStream = await queue.add(() => DownloadManager.getFile(file));
    } else {
        fileStream = await DownloadManager.getFile(file);
    }
    return new Response(fileStream).blob();
}

async function getOriginalConvertedFile(file: EnteFile, queue?: PQueue) {
    const fileBlob = await getOriginalFile(file, queue);
    if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        return await getRenderableImage(file.metadata.title, fileBlob);
    } else {
        const { imageFileName, imageData } = await decodeLivePhoto(
            file.metadata.title,
            fileBlob,
        );
        return await getRenderableImage(imageFileName, new Blob([imageData]));
    }
}

export async function getOriginalImageBitmap(file: EnteFile, queue?: PQueue) {
    const fileBlob = await getOriginalConvertedFile(file, queue);
    log.info("[MLService] Got file: ", file.id.toString());
    return getImageBlobBitmap(fileBlob);
}

export async function getThumbnailImageBitmap(file: EnteFile) {
    const thumb = await DownloadManager.getThumbnail(file);
    log.info("[MLService] Got thumbnail: ", file.id.toString());

    return getImageBlobBitmap(new Blob([thumb]));
}

export async function getLocalFileImageBitmap(
    enteFile: EnteFile,
    localFile: globalThis.File,
) {
    let fileBlob = localFile as Blob;
    fileBlob = await getRenderableImage(enteFile.metadata.title, fileBlob);
    return getImageBlobBitmap(fileBlob);
}

export async function getPeopleList(file: EnteFile): Promise<Array<Person>> {
    let startTime = Date.now();
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);
    log.info(
        "getPeopleList:mlFilesStore:getItem",
        Date.now() - startTime,
        "ms",
    );
    if (!mlFileData?.faces || mlFileData.faces.length < 1) {
        return [];
    }

    const peopleIds = mlFileData.faces
        .filter((f) => f.personId !== null && f.personId !== undefined)
        .map((f) => f.personId);
    if (!peopleIds || peopleIds.length < 1) {
        return [];
    }
    // log.info("peopleIds: ", peopleIds);
    startTime = Date.now();
    const peoplePromises = peopleIds.map(
        (p) => mlIDbStorage.getPerson(p) as Promise<Person>,
    );
    const peopleList = await Promise.all(peoplePromises);
    log.info(
        "getPeopleList:mlPeopleStore:getItems",
        Date.now() - startTime,
        "ms",
    );
    // log.info("peopleList: ", peopleList);

    return peopleList;
}

export async function getUnidentifiedFaces(
    file: EnteFile,
): Promise<Array<Face>> {
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);

    return mlFileData?.faces?.filter(
        (f) => f.personId === null || f.personId === undefined,
    );
}

export async function getAllPeople(limit: number = undefined) {
    let people: Array<Person> = await mlIDbStorage.getAllPeople();
    // await mlPeopleStore.iterate<Person, void>((person) => {
    //     people.push(person);
    // });
    people = people ?? [];
    return people
        .sort((p1, p2) => p2.files.length - p1.files.length)
        .slice(0, limit);
}
