import React from 'react';
import { IconButton, styled } from '@mui/material';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';
import uploadManager from 'services/upload/uploadManager';

const Wrapper = styled('div')`
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 1s ease;
    cursor: pointer;
    & .mobile-button {
        display: none;
    }
    @media (max-width: 624px) {
        & .mobile-button {
            display: block;
        }
        & .desktop-button {
            display: none;
        }
    }
`;

interface Iprops {
    openUploader: () => void;
}
function UploadButton({ openUploader }: Iprops) {
    return (
        <Wrapper
            style={{
                cursor: !uploadManager.shouldAllowNewUpload() && 'not-allowed',
            }}>
            <Button
                onClick={openUploader}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="desktop-button"
                color="secondary"
                startIcon={<FileUploadOutlinedIcon />}>
                {constants.UPLOAD}
            </Button>

            <IconButton
                onClick={openUploader}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="mobile-button">
                <FileUploadOutlinedIcon />
            </IconButton>
        </Wrapper>
    );
}

export default UploadButton;
