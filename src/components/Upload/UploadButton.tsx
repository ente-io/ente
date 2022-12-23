import React from 'react';
import { ButtonProps, IconButton, styled } from '@mui/material';
import FileUploadOutlinedIcon from '@mui/icons-material/FileUploadOutlined';
import { Button } from '@mui/material';
import constants from 'utils/strings/constants';
import uploadManager from 'services/upload/uploadManager';

const Wrapper = styled('div')<{ disableShrink: boolean }>`
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 1s ease;
    cursor: pointer;
    & .mobile-button {
        display: none;
    }
    ${({ disableShrink }) =>
        !disableShrink &&
        `@media (max-width: 624px) {
        & .mobile-button {
            display: block;
        }
        & .desktop-button {
            display: none;
        }
    }`}
`;

interface Iprops {
    openUploader: () => void;
    text?: string;
    color?: ButtonProps['color'];
    disableShrink?: boolean;
    icon?: JSX.Element;
}
function UploadButton({
    openUploader,
    text,
    color,
    disableShrink,
    icon,
}: Iprops) {
    return (
        <Wrapper
            disableShrink={disableShrink}
            style={{
                cursor: !uploadManager.shouldAllowNewUpload() && 'not-allowed',
            }}>
            <Button
                onClick={openUploader}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="desktop-button"
                color={color ?? 'secondary'}
                startIcon={icon ?? <FileUploadOutlinedIcon />}>
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
