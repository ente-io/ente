import { ensureLocalUser } from "@/next/local-user";
import log from "@/next/log";
import { cached } from "@ente/shared/storage/cache";
import { Skeleton, styled } from "@mui/material";
import { Legend } from "components/PhotoViewer/styledComponents/Legend";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import machineLearningService from "services/machineLearning/machineLearningService";
import { EnteFile } from "types/file";
import { Face, Person } from "types/machineLearning";
import { getPeopleList, getUnidentifiedFaces } from "utils/machineLearning";

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
                    <FaceCropImageView
                        url={person.displayImageUrl}
                        faceId={person.displayFaceId}
                    />
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
    const [faces, setFaces] = useState<Array<Face>>([]);

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
                            <FaceCropImageView
                                faceId={face.id}
                                url={face.crop?.imageUrl}
                            />
                        </FaceChip>
                    ))}
            </FaceChipContainer>
        </>
    );
}

interface FaceCropImageViewProps {
    url: string;
    faceId: string;
}

const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({
    url,
    faceId,
}) => {
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;

        async function loadImage() {
            let blob: Blob;
            if (!url) {
                blob = undefined;
            } else {
                const user = await ensureLocalUser();
                blob = await cached("face-crops", url, async () => {
                    try {
                        log.debug(
                            () =>
                                `ImageCacheView: regenerate face crop for ${faceId}`,
                        );
                        return machineLearningService.regenerateFaceCrop(
                            user.token,
                            user.id,
                            faceId,
                        );
                    } catch (e) {
                        log.error(
                            "ImageCacheView: regenerate face crop failed",
                            e,
                        );
                    }
                });
            }

            if (didCancel) return;
            setObjectURL(blob ? URL.createObjectURL(blob) : undefined);
        }

        loadImage();

        return () => {
            didCancel = true;
            if (objectURL) URL.revokeObjectURL(objectURL);
        };
    }, [url, faceId]);

    return objectURL ? (
        <img src={objectURL} />
    ) : (
        <Skeleton variant="circular" height={120} width={120} />
    );
};
