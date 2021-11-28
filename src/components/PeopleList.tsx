import React, { useState, useEffect } from 'react';
import TFJSImage from 'components/TFJSImage';
import { Person } from 'utils/machineLearning/types';
import { getAllPeople, getPeopleList } from 'utils/machineLearning';
import styled from 'styled-components';
import { File } from 'services/fileService';

const FaceChipContainer = styled.div`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    margin-top: 10px;
    margin-bottom: 10px;
`;

const FaceChip = styled.div`
    width: 112px;
    height: 112px;
    margin-right: 10px;
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
                    <TFJSImage faceImage={person.faceImage}></TFJSImage>
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

    const updateFaceImages = async () => {
        const people = await getPeopleList(props.file);
        setPeople(people);
    };

    useEffect(() => {
        // TODO: handle multiple async updates
        updateFaceImages();
    }, [props.file]);

    return <PeopleList people={people} onSelect={props.onSelect}></PeopleList>;
}

export interface AllPeopleListProps extends PeopleListPropsBase {
    limit?: number;
}

export function AllPeopleList(props: AllPeopleListProps) {
    const [people, setPeople] = useState<Array<Person>>([]);

    useEffect(() => {
        // TODO: handle multiple async updates
        async function updateFaceImages() {
            let people = await getAllPeople();
            if (props.limit) {
                people = people.slice(0, props.limit);
            }
            setPeople(people);
        }

        updateFaceImages();
        return () => {
            setPeople([]);
        };
    }, [props]);

    return <PeopleList people={people} onSelect={props.onSelect}></PeopleList>;
}
