import React from 'react';
import styled from 'styled-components';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';

const Wrapper = styled.div<{ isDisabled: boolean }>`
    position: fixed;
    display: flex;
    align-items: center;
    justify-content: center;
    top: 0;
    z-index: 100;
    min-height: 64px;
    right: 32px;
    transition: opacity 1s ease;
    cursor: pointer;
    opacity: ${(props) => (props.isDisabled ? 0 : 1)};
`;
function UploadButton({ isFirstFetch, openUploader }) {
    return (
        <Wrapper onClick={openUploader} isDisabled={isFirstFetch}>
            <Button variant="contained">
                <FileUploadOutlinedIcon sx={{ mr: 1 }} />
                {constants.UPLOAD}
            </Button>
        </Wrapper>
    );
}

export default UploadButton;
