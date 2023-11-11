import React, { useState, useEffect } from 'react';
import { Face, Person } from 'types/machineLearning';
import {
    getAllPeople,
    getPeopleList,
    getUnidentifiedFaces,
} from 'utils/machineLearning';
import { styled } from '@mui/material';
import { EnteFile } from 'types/file';
import { ImageCacheView } from './ImageViews';
import { CACHES } from '@ente/shared/storage/cacheStorage/constants';
import { Legend } from 'components/PhotoViewer/styledComponents/Legend';
import { addLogLine } from '@ente/shared/logging';
import { logError } from '@ente/shared/sentry';
import { t } from 'i18next';

const FaceChipContainer = styled('div')`
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-items: center;
    margin-top: 5px;
    margin-bottom: 5px;
    overflow: auto;
`;

const FaceChip = styled('div')<{ clickable?: boolean }>`
    width: 112px;
    height: 112px;
    margin: 5px;
    border-radius: 50%;
    overflow: hidden;
    position: relative;
    cursor: ${({ clickable }) => (clickable ? 'pointer' : 'normal')};
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
            }>
            {props.people.map((person, index) => (
                <FaceChip
                    key={person.id}
                    clickable={!!props.onSelect}
                    onClick={() =>
                        props.onSelect && props.onSelect(person, index)
                    }>
                    <ImageCacheView
                        url={person.displayImageUrl}
                        cacheName={CACHES.FACE_CROPS}
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
            addLogLine('calling getPeopleList');
            const startTime = Date.now();
            const people = await getPeopleList(props.file);
            addLogLine('getPeopleList', Date.now() - startTime, 'ms');
            addLogLine('getPeopleList done, didCancel: ', didCancel);
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
            <Legend>{t('PEOPLE')}</Legend>
            <PeopleList people={people} onSelect={props.onSelect}></PeopleList>
        </div>
    );
}

export interface AllPeopleListProps extends PeopleListPropsBase {
    limit?: number;
}

export function AllPeopleList(props: AllPeopleListProps) {
    const [people, setPeople] = useState<Array<Person>>([]);

    useEffect(() => {
        let didCancel = false;

        async function updateFaceImages() {
            try {
                let people = await getAllPeople();
                if (props.limit) {
                    people = people.slice(0, props.limit);
                }
                !didCancel && setPeople(people);
            } catch (e) {
                logError(e, 'updateFaceImages failed');
            }
        }
        updateFaceImages();
        return () => {
            didCancel = true;
        };
    }, [props.limit]);

    return <PeopleList people={people} onSelect={props.onSelect}></PeopleList>;
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
                <Legend>{t('UNIDENTIFIED_FACES')}</Legend>
            </div>
            <FaceChipContainer>
                {faces &&
                    faces.map((face, index) => (
                        <FaceChip key={index}>
                            <ImageCacheView
                                url={face.crop?.imageUrl}
                                cacheName={CACHES.FACE_CROPS}
                            />
                        </FaceChip>
                    ))}
            </FaceChipContainer>
        </>
    );
}
