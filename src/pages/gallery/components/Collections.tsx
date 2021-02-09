import React from 'react';
import { collection } from 'services/collectionService';
import styled from 'styled-components';

interface CollectionProps {
    collections: collection[];
    selected?: string;
    selectCollection: (id?: number) => void;
}

const Container = styled.div`
    margin: 0 auto;
    overflow-y: hidden;
    height: 40px;
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
    flex: 1;
    white-space: nowrap;
    overflow: auto;
    max-width: 100%;
`;
const Chip = styled.button<{ active: boolean }>`
    border-radius: 20px;
    padding: 2px 10px;
    margin: 2px 5px 2px 2px;
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

    return (
        <Container>
            <Wrapper>
                <Chip active={!selected} onClick={clickHandler()}>
                    All
                </Chip>
                {collections?.map((item) => (
                    <Chip
                        key={item.id}
                        active={selected === item.id.toString()}
                        onClick={clickHandler(item.id)}
                    >
                        {item.name}
                    </Chip>
                ))}
            </Wrapper>
        </Container>
    );
}
