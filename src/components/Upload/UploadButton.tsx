import React from 'react';
import { IconButton, styled } from '@mui/material';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';

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
        <Wrapper onClick={openUploader}>
            <Button
                className="desktop-button"
                color="secondary"
                startIcon={<FileUploadOutlinedIcon />}>
                {constants.UPLOAD}
            </Button>
            <IconButton className="mobile-button">
                <FileUploadOutlinedIcon />
            </IconButton>
        </Wrapper>
    );
}

export default UploadButton;
