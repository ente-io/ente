import { EnteFile } from "@/new/photos/types/file";
import { blobCache } from "@/next/blob-cache";
import { Skeleton, styled } from "@mui/material";
import { Legend } from "components/PhotoViewer/styledComponents/Legend";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { unidentifiedFaceIDs } from "services/face/indexer";
import type { Person } from "services/face/people";

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
}

export function PhotoPeopleList() {
    return <></>;
}

export function UnidentifiedFaces({ file }: { file: EnteFile }) {
    const [faceIDs, setFaceIDs] = useState<string[]>([]);

    useEffect(() => {
        let didCancel = false;

        (async () => {
            const faceIDs = await unidentifiedFaceIDs(file);
            !didCancel && setFaceIDs(faceIDs);
        })();

        return () => {
            didCancel = true;
        };
    }, [file]);

    if (faceIDs.length == 0) return <></>;

    return (
        <>
            <div>
                <Legend>{t("UNIDENTIFIED_FACES")}</Legend>
            </div>
            <FaceChipContainer>
                {faceIDs.map((faceID) => (
                    <FaceChip key={faceID}>
                        <FaceCropImageView {...{ faceID }} />
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
