import React from 'react';
import { ButtonProps, IconButton, styled } from '@mui/material';
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
    text?: string;
    color?: ButtonProps['color'];
}
function UploadButton({ openUploader, text, color }: Iprops) {
    return (
        <Wrapper
            style={{
                cursor: !uploadManager.shouldAllowNewUpload() && 'not-allowed',
            }}>
            <Button
                onClick={openUploader}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="desktop-button"
                color={color ?? 'secondary'}
                startIcon={<FileUploadOutlinedIcon />}>
                {text ?? constants.UPLOAD}
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
