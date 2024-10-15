import { useIsSmallWidth } from "@/base/hooks";
import { pt } from "@/base/i18n";
import type { EnteFile } from "@/media/file";
import { faceCrop, type AnnotatedFaceID } from "@/new/photos/services/ml";
import type { Person, PreviewableFace } from "@/new/photos/services/ml/people";
import { Skeleton, Typography, styled } from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { UnstyledButton } from "./UnstyledButton";

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
    const isSmallWidth = useIsSmallWidth();
    return (
        <SearchPeopleContainer
            sx={{ justifyContent: people.length > 3 ? "center" : "start" }}
        >
            {people.slice(0, isSmallWidth ? 6 : 7).map((person) => (
                <SearchPersonButton
                    key={person.id}
                    onClick={() => onSelectPerson(person)}
                >
                    <FaceCropImageView
                        faceID={person.displayFaceID}
                        file={person.displayFaceFile}
                        placeholderDimension={87}
                    />
                </SearchPersonButton>
            ))}
        </SearchPeopleContainer>
    );
};

const SearchPeopleContainer = styled("div")`
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 5px;
    margin-block-start: 12px;
    margin-block-end: 15px;
`;

const SearchPersonButton = styled(UnstyledButton)(
    ({ theme }) => `
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

export interface AnnotatedFacePeopleListProps {
    /**
     * The {@link EnteFile} whose information we are showing.
     */
    file: EnteFile;
    /**
     * The list of faces in the file that are associated with a person.
     */
    annotatedFaceIDs: AnnotatedFaceID[];
    /**
     * Called when the user selects a face in the list.
     */
    onSelectFace: (annotatedFaceID: AnnotatedFaceID) => void;
}

/**
 * Show the list of faces in the given file that are associated with a specific
 * person.
 */
export const AnnotatedFacePeopleList: React.FC<
    AnnotatedFacePeopleListProps
> = ({ file, annotatedFaceIDs, onSelectFace }) => {
    if (annotatedFaceIDs.length == 0) return <></>;

    return (
        <>
            <Typography variant="large" p={1}>
                {t("people")}
            </Typography>
            <FileFaceList>
                {annotatedFaceIDs.map((annotatedFaceID) => (
                    <AnnotatedFaceButton
                        key={annotatedFaceID.faceID}
                        onClick={() => onSelectFace(annotatedFaceID)}
                    >
                        <FaceCropImageView
                            faceID={annotatedFaceID.faceID}
                            file={file}
                            placeholderDimension={112}
                        />
                    </AnnotatedFaceButton>
                ))}
            </FileFaceList>
        </>
    );
};

const FileFaceList = styled("div")`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    gap: 5px;
    margin: 5px;
`;

const AnnotatedFaceButton = styled(UnstyledButton)(
    ({ theme }) => `
    width: 112px;
    height: 112px;
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

export interface UnclusteredFaceListProps {
    /**
     * The {@link EnteFile} whose information we are showing.
     */
    file: EnteFile;
    /**
     * The list of faces in the file that are not associated with a person.
     */
    faceIDs: string[];
}

/**
 * Show the list of faces in the given file that are not associated with a
 * specific person.
 */
export const UnclusteredFaceList: React.FC<UnclusteredFaceListProps> = ({
    file,
    faceIDs,
}) => {
    if (faceIDs.length == 0) return <></>;

    return (
        <>
            <Typography variant="large" p={1}>
                {pt("Other faces")}
                {/*t("UNIDENTIFIED_FACES")  TODO-Cluster */}
            </Typography>
            <FileFaceList>
                {faceIDs.map((faceID) => (
                    <UnclusteredFace key={faceID}>
                        <FaceCropImageView
                            placeholderDimension={112}
                            {...{ file, faceID }}
                        />
                    </UnclusteredFace>
                ))}
            </FileFaceList>
        </>
    );
};

const UnclusteredFace = styled("div")`
    width: 112px;
    height: 112px;
    margin: 5px;
    border-radius: 50%;
    overflow: hidden;
    & > img {
        width: 100%;
        height: 100%;
    }
`;

export interface SuggestionFaceListProps {
    /**
     * Faces, each annotated with the corresponding {@link EnteFile}, to show in
     * the list.
     */
    faces: PreviewableFace[];
}

/**
 * Show the sampling of faces from a given cluster that is being offered as a
 * suggestion to the user.
 */
export const SuggestionFaceList: React.FC<SuggestionFaceListProps> = ({
    faces,
}) => {
    return (
        <SuggestionFaceList_>
            {faces.map(({ file, faceID }) => (
                <SuggestionFace key={faceID}>
                    <FaceCropImageView
                        placeholderDimension={112}
                        {...{ file, faceID }}
                    />
                </SuggestionFace>
            ))}
        </SuggestionFaceList_>
    );
};

const SuggestionFaceList_ = styled("div")`
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
`;

const SuggestionFace = styled("div")`
    width: 87px;
    height: 87px;
    border-radius: 50%;
    overflow: hidden;
    & > img {
        width: 100%;
        height: 100%;
    }
`;

type FaceCropImageViewProps = PreviewableFace & {
    /** Width and height for the placeholder. */
    placeholderDimension: number;
};

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
    file,
    placeholderDimension,
}) => {
    const [url, setURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;

        void faceCrop(faceID, file).then((url) => !didCancel && setURL(url));

        return () => {
            didCancel = true;
        };
    }, [faceID, file]);

    return url ? (
        <img style={{ objectFit: "cover" }} src={url} />
    ) : (
        <Skeleton
            variant="circular"
            animation="wave"
            sx={{
                backgroundColor: (theme) => theme.colors.background.elevated2,
            }}
            width={placeholderDimension}
            height={placeholderDimension}
        />
    );
};
