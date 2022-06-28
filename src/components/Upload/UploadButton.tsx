import React from 'react';
import { IconButton, styled } from '@mui/material';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';

const Wrapper = styled('div')<{ isDisabled: boolean }>`
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 1s ease;
    cursor: pointer;
    opacity: ${(props) => (props.isDisabled ? 0 : 1)};
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
    isFirstFetch: boolean;
    openUploader: () => void;
}
function UploadButton({ isFirstFetch, openUploader }: Iprops) {
    return (
        <Wrapper onClick={openUploader} isDisabled={isFirstFetch}>
            <Button
                className="desktop-button"
                color="secondary"
                sx={{ borderRadius: '2px' }}
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
