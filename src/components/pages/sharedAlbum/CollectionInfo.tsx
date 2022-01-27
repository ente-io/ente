import React from 'react';
import styled from 'styled-components';
import { Collection } from 'types/collection';

interface Iprops {
    collection: Collection;
}

const Info = styled.h5`
    padding: 5px 24px;
    margin: 20px;
    border-bottom: 2px solid #5a5858;
`;

export function CollectionInfo(props: Iprops) {
    if (!props.collection) {
        return <></>;
    }
    return <Info>{props.collection.name}</Info>;
}
