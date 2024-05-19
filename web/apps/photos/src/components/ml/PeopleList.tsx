import { blobCache } from "@/next/blob-cache";
import log from "@/next/log";
import { Skeleton, styled } from "@mui/material";
import { Legend } from "components/PhotoViewer/styledComponents/Legend";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import mlIDbStorage from "services/face/db";
import type { Person } from "services/face/people";
import type { Face, MlFileData } from "services/face/types";
import { EnteFile } from "types/file";

const FaceChipContainer = styled("div")`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    margin-top: 5px;
    margin-bottom: 5px;
    overflow: auto;
`;

const FaceChip = styled("div")<{ clickable?: boolean }>`
    width: 112px;
    height: 112px;
    margin: 5px;
    border-radius: 50%;
    overflow: hidden;
    position: relative;
    cursor: ${({ clickable }) => (clickable ? "pointer" : "normal")};
    & > img {
        width: 100%;
        height: 100%;
    }
`;

interface PeopleListPropsBase {
    onSelect?: (person: Person, index: number) => void;
}

export interface PeopleListProps extends PeopleListPropsBase {
    people: Array<Person>;
    maxRows?: number;
}

export const PeopleList = React.memo((props: PeopleListProps) => {
    return (
        <FaceChipContainer
            style={
                props.maxRows && {
                    maxHeight: props.maxRows * 122 + 28,
                }
            }
        >
            {props.people.map((person, index) => (
                <FaceChip
                    key={person.id}
                    clickable={!!props.onSelect}
                    onClick={() =>
                        props.onSelect && props.onSelect(person, index)
                    }
                >
                    <FaceCropImageView faceID={person.displayFaceId} />
                </FaceChip>
            ))}
        </FaceChipContainer>
    );
});

export interface PhotoPeopleListProps extends PeopleListPropsBase {
    file: EnteFile;
    updateMLDataIndex: number;
}

export function PhotoPeopleList(props: PhotoPeopleListProps) {
    const [people, setPeople] = useState<Array<Person>>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            log.info("calling getPeopleList");
            const startTime = Date.now();
            const people = await getPeopleList(props.file);
            log.info(`getPeopleList ${Date.now() - startTime} ms`);
            log.info(`getPeopleList done, didCancel: ${didCancel}`);
            !didCancel && setPeople(people);
        }

        updateFaceImages();

        return () => {
            didCancel = true;
        };
    }, [props.file, props.updateMLDataIndex]);

    if (people.length === 0) return <></>;

    return (
        <div>
            <Legend>{t("PEOPLE")}</Legend>
            <PeopleList people={people} onSelect={props.onSelect}></PeopleList>
        </div>
    );
}

export function UnidentifiedFaces(props: {
    file: EnteFile;
    updateMLDataIndex: number;
}) {
    const [faces, setFaces] = useState<Face[]>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            const faces = await getUnidentifiedFaces(props.file);
            !didCancel && setFaces(faces);
        }

        updateFaceImages();

        return () => {
            didCancel = true;
        };
    }, [props.file, props.updateMLDataIndex]);

    if (!faces || faces.length === 0) return <></>;

    return (
        <>
            <div>
                <Legend>{t("UNIDENTIFIED_FACES")}</Legend>
            </div>
            <FaceChipContainer>
                {faces &&
                    faces.map((face, index) => (
                        <FaceChip key={index}>
                            <FaceCropImageView faceID={face.id} />
                        </FaceChip>
                    ))}
            </FaceChipContainer>
        </>
    );
}

interface FaceCropImageViewProps {
    faceID: string;
}

const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({ faceID }) => {
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;
        const electron = globalThis.electron;

        if (faceID && electron) {
            electron
                .legacyFaceCrop(faceID)
                .then(async (data) => {
                    if (data) return data;
                    /*
                    TODO(MR): Also, get this to work on web too.
                cachedOrNew("face-crops", cacheKey, async () => {
                return machineLearningService.regenerateFaceCrop(
                    faceId,
                );
                })*/
                    const cache = await blobCache("face-crops");
                    return await cache.get(faceID);
                })
                .then((data) => {
                    if (data) {
                        const blob = new Blob([data]);
                        if (!didCancel) setObjectURL(URL.createObjectURL(blob));
                    }
                });
        } else setObjectURL(undefined);

        return () => {
            didCancel = true;
            if (objectURL) URL.revokeObjectURL(objectURL);
        };
    }, [faceID]);

    return objectURL ? (
        <img src={objectURL} />
    ) : (
        <Skeleton variant="circular" height={120} width={120} />
    );
};

async function getPeopleList(file: EnteFile): Promise<Person[]> {
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

async function getUnidentifiedFaces(file: EnteFile): Promise<Array<Face>> {
    const mlFileData: MlFileData = await mlIDbStorage.getFile(file.id);

    return mlFileData?.faces?.filter(
        (f) => f.personId === null || f.personId === undefined,
    );
}
