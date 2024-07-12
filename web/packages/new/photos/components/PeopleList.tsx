import {
    regenerateFaceCropsIfNeeded,
    unidentifiedFaceIDs,
} from "@/new/photos/services/ml";
import type { Person } from "@/new/photos/services/ml/people";
import type { EnteFile } from "@/new/photos/types/file";
import { blobCache } from "@/next/blob-cache";
import { Skeleton, Typography, styled } from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";

export interface PeopleListProps {
    people: Person[];
    maxRows: number;
    onSelect?: (person: Person, index: number) => void;
}

export const PeopleList: React.FC<PeopleListProps> = ({
    people,
    maxRows,
    onSelect,
}) => {
    return (
        <FaceChipContainer style={{ maxHeight: maxRows * 122 + 28 }}>
            {people.map((person, index) => (
                <FaceChip
                    key={person.id}
                    clickable={!!onSelect}
                    onClick={() => onSelect && onSelect(person, index)}
                >
                    <FaceCropImageView faceID={person.displayFaceId} />
                </FaceChip>
            ))}
        </FaceChipContainer>
    );
};

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

export interface PhotoPeopleListProps {
    file: EnteFile;
    onSelect?: (person: Person, index: number) => void;
}

export function PhotoPeopleList() {
    return <></>;
}

interface UnidentifiedFacesProps {
    enteFile: EnteFile;
}

/**
 * Show the list of faces in the given file that are not linked to a specific
 * person ("face cluster").
 */
export const UnidentifiedFaces: React.FC<UnidentifiedFacesProps> = ({
    enteFile,
}) => {
    const [faceIDs, setFaceIDs] = useState<string[]>([]);
    const [didRegen, setDidRegen] = useState(false);

    useEffect(() => {
        let didCancel = false;

        const go = async () => {
            const faceIDs = await unidentifiedFaceIDs(enteFile);
            !didCancel && setFaceIDs(faceIDs);
            // Don't block for the regeneration to happen. If anything got
            // regenerated, the result will be true, in response to which we'll
            // change the key of the face list and cause it to be rerendered
            // (fetching the regenerated crops).
            void regenerateFaceCropsIfNeeded(enteFile).then((r) =>
                setDidRegen(r),
            );
        };

        void go();

        return () => {
            didCancel = true;
        };
    }, [enteFile]);

    if (faceIDs.length == 0) return <></>;

    return (
        <>
            <Typography variant="large" p={1}>
                {t("UNIDENTIFIED_FACES")}
            </Typography>
            <FaceChipContainer key={didRegen ? 1 : 0}>
                {faceIDs.map((faceID) => (
                    <FaceChip key={faceID}>
                        <FaceCropImageView {...{ faceID }} />
                    </FaceChip>
                ))}
            </FaceChipContainer>
        </>
    );
};

interface FaceCropImageViewProps {
    faceID: string;
}

/**
 * An image view showing the face crop for the given {@link faceID}.
 *
 * The image is read from the "face-crops" {@link BlobCache}. While the image is
 * being fetched, or if it doesn't exist, a placeholder is shown.
 */
const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({ faceID }) => {
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;
        if (faceID) {
            void blobCache("face-crops")
                .then((cache) => cache.get(faceID))
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
        // TODO: The linter warning is actually correct, objectURL should be a
        // dependency, but adding that require reworking this code first.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [faceID]);

    return objectURL ? (
        <img style={{ objectFit: "cover" }} src={objectURL} />
    ) : (
        <Skeleton variant="circular" height={120} width={120} />
    );
};
