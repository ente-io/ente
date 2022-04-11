import React from 'react';
import { FixedSizeList as List } from 'react-window';
import styled from 'styled-components';

interface Iprops {
    fileList: any[];
}

export const Wrapper = styled.div`
    padding-left: 30px;
    margin-top: 15px;
    margin-bottom: 0px;
`;

const ItemLiWrapper = styled.li`
    padding-left: 5px;
    color: #ccc;
`;

export default function FileList(props: Iprops) {
    const Row = ({ index, style }) => (
        <ItemLiWrapper style={style}>{props.fileList[index]}</ItemLiWrapper>
    );

    return (
        <Wrapper>
            <List
                height={Math.min(35 * props.fileList.length, 160)}
                width={'100%'}
                itemSize={35}
                itemCount={props.fileList.length}>
                {Row}
            </List>
        </Wrapper>
    );
}
