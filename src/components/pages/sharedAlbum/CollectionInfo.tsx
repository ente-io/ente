import React from 'react';
import styled from 'styled-components';
import { Collection } from 'types/collection';

interface Iprops {
    collection: Collection;
}

const Info = styled.h5`
    margin: 20px;
`;

export function CollectionInfo(props: Iprops) {
    if (!props.collection) {
        return <></>;
    }
    return <Info>{props.collection.name}</Info>;
}
