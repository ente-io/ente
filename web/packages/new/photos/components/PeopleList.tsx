import { Skeleton, styled, Typography } from "@mui/material";
import { useIsSmallWidth } from "ente-base/components/utils/hooks";
import type { EnteFile } from "ente-media/file";
import { faceCrop, type AnnotatedFaceID } from "ente-new/photos/services/ml";
import type {
    Person,
    PreviewableFace,
} from "ente-new/photos/services/ml/people";
import React, { useEffect, useState } from "react";
import { UnstyledButton } from "./UnstyledButton";

export interface SearchPeopleListProps {
    people: Person[];
    onSelectPerson: (personID: string) => void;
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
            sx={[
                people.length > 3
                    ? { justifyContent: "center" }
                    : { justifyContent: "start" },
            ]}
        >
            {people.slice(0, isSmallWidth ? 6 : 7).map((person) => (
                <SearchPersonButton
                    key={person.id}
                    onClick={() => onSelectPerson(person.id)}
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
        outline: 1px solid ${theme.vars.palette.stroke.faint};
        outline-offset: 2px;
    }
`,
);

export interface FilePeopleListProps {
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
export const FilePeopleList: React.FC<FilePeopleListProps> = ({
    file,
    annotatedFaceIDs,
    onSelectFace,
}) => (
    <FilePeopleList_>
        {annotatedFaceIDs.map((annotatedFaceID) => (
            <AnnotatedFaceButton
                key={annotatedFaceID.faceID}
                onClick={() => onSelectFace(annotatedFaceID)}
            >
                <FaceCropImageView
                    faceID={annotatedFaceID.faceID}
                    file={file}
                    placeholderDimension={65}
                />
                <Typography variant="small" sx={{ color: "text.muted" }}>
                    {annotatedFaceID.personName}
                </Typography>
            </AnnotatedFaceButton>
        ))}
    </FilePeopleList_>
);

const FilePeopleList_ = styled("div")`
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-block-end: 5px;
`;

const AnnotatedFaceButton = styled(UnstyledButton)(
    ({ theme }) => `
    width: 65px;
    display: flex;
    flex-direction: column;
    gap: 2px;
    & > img {
        width: 100%;
        aspect-ratio: 1;
        border-radius: 50%;
        overflow: hidden;
    }
    & > img:hover {
        outline: 1px solid ${theme.vars.palette.stroke.faint};
        outline-offset: 2px;
    }
`,
);

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
                        placeholderDimension={87}
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
            sx={{ backgroundColor: "background.paper2" }}
            width={placeholderDimension}
            height={placeholderDimension}
        />
    );
};
