import { blobCache } from "@/next/blob-cache";
import { Skeleton, styled } from "@mui/material";
import { Legend } from "components/PhotoViewer/styledComponents/Legend";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import mlIDbStorage from "services/face/db-old";
import type { Person } from "services/face/people";
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

export function PhotoPeopleList() {
    return <></>;
}

export function UnidentifiedFaces(props: {
    file: EnteFile;
    updateMLDataIndex: number;
}) {
    const [faces, setFaces] = useState<{ id: string }[]>([]);

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
        if (faceID) {
            blobCache("face-crops")
                .then((cache) => cache.get(faceID))
                .then((data) => {
                    /*
                    TODO(MR): regen if needed and get this to work on web too.
                    cachedOrNew("face-crops", cacheKey, async () => {
                        return regenerateFaceCrop(faceId);
                    })*/
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

async function getUnidentifiedFaces(file: EnteFile): Promise<{ id: string }[]> {
    const mlFileData = await mlIDbStorage.getFile(file.id);

    return mlFileData?.faces?.filter(
        (f) => f.personId === null || f.personId === undefined,
    );
}
