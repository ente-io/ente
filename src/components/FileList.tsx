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

export default function FileList(props: Iprops) {
    const Row = ({ index, style }) => (
        <div style={style}>{props.fileList[index % props.fileList.length]}</div>
    );

    return (
        <Wrapper>
            <List
                height={Math.min(30 * props.fileList.length, 135)}
                width={'100%'}
                itemSize={30}
                itemCount={props.fileList.length}>
                {Row}
            </List>
        </Wrapper>
    );
}
