import { Box, Tooltip } from '@mui/material';
import React from 'react';
import { FixedSizeList as List } from 'react-window';

interface Iprops {
    fileList: any[];
}

export default function FileList(props: Iprops) {
    const Row = ({ index, style }) => (
        <Tooltip
            title={props.fileList[index]}
            placement="bottom-start"
            enterDelay={300}
            enterNextDelay={300}>
            <div style={style}>{props.fileList[index]}</div>
        </Tooltip>
    );

    return (
        <Box pl={2}>
            <List
                height={Math.min(35 * props.fileList.length, 160)}
                width={'100%'}
                itemSize={35}
                itemCount={props.fileList.length}>
                {Row}
            </List>
        </Box>
    );
}
