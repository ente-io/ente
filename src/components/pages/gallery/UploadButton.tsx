import React from 'react';
import styled from 'styled-components';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';

const Wrapper = styled.div<{ isDisabled: boolean }>`
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 1s ease;
    cursor: pointer;
    opacity: ${(props) => (props.isDisabled ? 0 : 1)};
`;
function UploadButton({ isFirstFetch, openUploader }) {
    return (
        <Wrapper onClick={openUploader} isDisabled={isFirstFetch}>
            <Button
                color="secondary"
                sx={{ borderRadius: '2px' }}
                startIcon={<FileUploadOutlinedIcon />}>
                {constants.UPLOAD}
            </Button>
        </Wrapper>
    );
}

export default UploadButton;
