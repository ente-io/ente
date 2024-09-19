import { useIsMobileWidth } from "@/base/hooks";
import { faceCrop, unidentifiedFaceIDs } from "@/new/photos/services/ml";
import type { Person } from "@/new/photos/services/ml/cgroups";
import type { EnteFile } from "@/new/photos/types/file";
import { Skeleton, Typography, styled } from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";

export interface SearchPeopleListProps {
    people: Person[];
    onSelectPerson: (person: Person) => void;
}

/**
 * Shows a list of {@link Person}s in the empty state of the search bar.
 */
export const SearchPeopleList: React.FC<SearchPeopleListProps> = ({
    people,
    onSelectPerson,
}) => {
    const isMobileWidth = useIsMobileWidth();
    return (
        <SearchPeopleContainer>
            {people.slice(0, isMobileWidth ? 6 : 7).map((person) => (
                <SearchPeopleButton
                    key={person.id}
                    onClick={() => onSelectPerson(person)}
                >
                    <FaceCropImageView
                        faceID={person.displayFaceID}
                        enteFile={person.displayFaceFile}
                        placeholderDimension={87}
                    />
                </SearchPeopleButton>
            ))}
        </SearchPeopleContainer>
    );
};

const SearchPeopleContainer = styled("div")`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    gap: 5px;
    margin-block: 16px;
    /* On very small (~ < 375px) mobile screens 6 faces won't fit in 2 rows.
       Clip the third one. */
    overflow: hidden;
    /* Keep enough space for the button outline (since we overflow hidden). */
    padding-inline: 2px;
    padding-block: 4px;
`;

const SearchPeopleButton = styled("button")(
    ({ theme }) => `
    /* Reset some button defaults */
    border: 0;
    padding: 0;
    /* Button should do this for us, but it isn't working inside the select */
    cursor: pointer;
    width: 87px;
    height: 87px;
    border-radius: 50%;
    overflow: hidden;
    & > img {
        width: 100%;
        height: 100%;
    }
    :hover {
        outline: 1px solid ${theme.colors.stroke.faint};
        outline-offset: 2px;
    }
`,
);

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

    useEffect(() => {
        let didCancel = false;

        const go = async () => {
            const faceIDs = await unidentifiedFaceIDs(enteFile);
            !didCancel && setFaceIDs(faceIDs);
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
            <FaceChipContainer>
                {faceIDs.map((faceID) => (
                    <FaceChip key={faceID}>
                        <FaceCropImageView
                            placeholderDimension={112}
                            {...{ enteFile, faceID }}
                        />
                    </FaceChip>
                ))}
            </FaceChipContainer>
        </>
    );
};

interface FaceCropImageViewProps {
    /** The ID of the face to display. */
    faceID: string;
    /** The {@link EnteFile} which contains this face. */
    enteFile: EnteFile;
    /** Width and height for the placeholder. */
    placeholderDimension: number;
}

/**
 * An image view showing the face crop for the given face.
 *
 * The image is read from the "face-crops" {@link BlobCache}, regenerating it if
 * needed (which is why also need to pass the associated file).
 *
 * While the image is being fetched or regenerated, or if it doesn't exist, a
 * placeholder is shown.
 */
const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({
    faceID,
    enteFile,
    placeholderDimension,
}) => {
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;
        let thisObjectURL: string | undefined;

        void faceCrop(faceID, enteFile).then((blob) => {
            if (blob && !didCancel)
                setObjectURL((thisObjectURL = URL.createObjectURL(blob)));
        });

        return () => {
            didCancel = true;
            if (thisObjectURL) URL.revokeObjectURL(thisObjectURL);
        };
    }, [faceID, enteFile]);

    return objectURL ? (
        <img style={{ objectFit: "cover" }} src={objectURL} />
    ) : (
        <Skeleton
            variant="circular"
            width={placeholderDimension}
            height={placeholderDimension}
        />
    );
};
