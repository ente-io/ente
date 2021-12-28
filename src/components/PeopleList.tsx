import React, { useState, useEffect } from 'react';
import { FaceImageBlob, Person } from 'types/machineLearning';
import {
    getAllPeople,
    getPeopleList,
    getUnidentifiedFaces,
} from 'utils/machineLearning';
import styled from 'styled-components';
import { File } from 'services/fileService';
import { ImageBlobView } from './ImageViews';

const FaceChipContainer = styled.div`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    margin-top: 5px;
    margin-bottom: 5px;
`;

const FaceChip = styled.div`
    width: 112px;
    height: 112px;
    margin: 5px;
    border-radius: 50%;
    overflow: hidden;
    position: relative;
    cursor: pointer;
`;

interface PeopleListPropsBase {
    onSelect?: (person: Person, index: number) => void;
}

export interface PeopleListProps extends PeopleListPropsBase {
    people: Array<Person>;
}

export function PeopleList(props: PeopleListProps) {
    return (
        <FaceChipContainer>
            {props.people.map((person, index) => (
                <FaceChip
                    key={index}
                    onClick={() =>
                        props.onSelect && props.onSelect(person, index)
                    }>
                    <ImageBlobView blob={person.faceImage}></ImageBlobView>
                </FaceChip>
            ))}
        </FaceChipContainer>
    );
}

export interface PhotoPeopleListProps extends PeopleListPropsBase {
    file: File;
}

export function PhotoPeopleList(props: PhotoPeopleListProps) {
    const [people, setPeople] = useState<Array<Person>>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            const people = await getPeopleList(props.file);
            !didCancel && setPeople(people);
        }

        updateFaceImages();

        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return <PeopleList people={people} onSelect={props.onSelect}></PeopleList>;
}

export interface AllPeopleListProps extends PeopleListPropsBase {
    limit?: number;
}

export function AllPeopleList(props: AllPeopleListProps) {
    const [people, setPeople] = useState<Array<Person>>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            let people = await getAllPeople();
            if (props.limit) {
                people = people.slice(0, props.limit);
            }
            !didCancel && setPeople(people);
        }

        updateFaceImages();

        return () => {
            didCancel = true;
        };
    }, [props.limit]);

    return <PeopleList people={people} onSelect={props.onSelect}></PeopleList>;
}

export function UnidentifiedFaces(props: { file: File }) {
    const [faceImages, setFaceImages] = useState<Array<FaceImageBlob>>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            const faceImages = await getUnidentifiedFaces(props.file);
            !didCancel && setFaceImages(faceImages);
        }

        updateFaceImages();

        return () => {
            didCancel = true;
        };
    }, [props.file]);

    return (
        <FaceChipContainer>
            {faceImages &&
                faceImages.map((faceImage, index) => (
                    <FaceChip key={index}>
                        <ImageBlobView blob={faceImage}></ImageBlobView>
                    </FaceChip>
                ))}
        </FaceChipContainer>
    );
}
