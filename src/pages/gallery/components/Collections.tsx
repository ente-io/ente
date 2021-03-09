import React from 'react';
import { collection } from 'services/collectionService';
import styled from 'styled-components';

interface CollectionProps {
    collections: collection[];
    selected?: number;
    selectCollection: (id?: number) => void;
}

const Container = styled.div`
    margin: 0 auto;
    overflow-y: hidden;
    height: 50px;
    display: flex;
    max-width: 100%;

    @media (min-width: 1000px) {
        width: 1000px;
    }

    @media (min-width: 450px) and (max-width: 1000px) {
        width: 600px;
    }

    @media (max-width: 450px) {
        width: 100%;
    }
`;

const Wrapper = styled.div`
    height: 70px;
    margin-top: 10px;
    flex: 1;
    white-space: nowrap;
    overflow: auto;
    max-width: 100%;
`;
const Chip = styled.button<{ active: boolean }>`
    border-radius: 8px;
    padding: 4px 14px;
    margin: 2px 8px 2px 2px;
    border: none;
    background-color: ${(props) =>
        props.active ? '#fff' : 'rgba(255, 255, 255, 0.3)'};
    outline: none !important;

    &:focus {
        box-shadow: 0 0 0 2px #2666cc;
        background-color: #eee;
    }
`;

export default function Collections(props: CollectionProps) {
    const { selected, collections, selectCollection } = props;
    const clickHandler = (id?: number) => () => selectCollection(id);
    if (collections.length == 0) {
        return <Container />;
    }
    return (
        <Container>
            <Wrapper>
                <Chip active={!selected} onClick={clickHandler()}>
                    All
                </Chip>
                {collections?.map((item) => (
                    <Chip
                        key={item.id}
                        active={selected === item.id}
                        onClick={clickHandler(item.id)}
                    >
                        {item.name}
                    </Chip>
                ))}
            </Wrapper>
        </Container>
    );
}
