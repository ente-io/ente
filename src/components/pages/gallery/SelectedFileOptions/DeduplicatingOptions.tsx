import { IconButton } from 'components/Container';
import { IconWithMessage } from '.';
import constants from 'utils/strings/constants';
import DeleteIcon from 'components/icons/DeleteIcon';
import React from 'react';
import styled from 'styled-components';

const VerticalLine = styled.div`
    position: absolute;
    width: 1px;
    top: 0;
    bottom: 0;
    background: #303030;
`;

export default function DeduplicatingOptions({ trashHandler }) {
    return (
        <>
            <div>
                <VerticalLine />
            </div>
            <IconWithMessage message={constants.DELETE}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </IconWithMessage>
        </>
    );
}
