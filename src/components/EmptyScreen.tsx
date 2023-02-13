import React, { useContext } from 'react';
import { Button, styled, Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { DeduplicateContext } from 'pages/deduplicate';
import VerticallyCentered, { FlexWrapper } from './Container';
import uploadManager from 'services/upload/uploadManager';
import AddPhotoAlternateIcon from '@mui/icons-material/AddPhotoAlternate';
import FolderIcon from '@mui/icons-material/Folder';

const Wrapper = styled(VerticallyCentered)`
    & > svg {
        filter: drop-shadow(3px 3px 5px rgba(45, 194, 98, 0.5));
    }
`;

export default function EmptyScreen({ openUploader }) {
    const deduplicateContext = useContext(DeduplicateContext);
    return (
        <Wrapper>
            {deduplicateContext.isOnDeduplicatePage ? (
                <div
                    style={{
                        color: '#a6a6a6',
                        fontSize: '18px',
                    }}>
                    {constants.NO_DUPLICATES_FOUND}
                </div>
            ) : (
                <>
                    <VerticallyCentered
                        sx={{
                            flex: 'none',
                            pt: 1.5,
                            pb: 1.5,
                        }}>
                        <VerticallyCentered sx={{ flex: 'none' }}>
                            {constants.WELCOME_TO_ENTE()}
                        </VerticallyCentered>
                        <Typography
                            variant="body1"
                            mt={3.5}
                            color="text.secondary">
                            {constants.WHERE_YOUR_BEST_PHOTOS_LIVE}
                        </Typography>
                    </VerticallyCentered>
                    <img
                        height={287.57}
                        src="/images/empty-state/ente_duck.png"
                        srcSet="/images/empty-state/ente_duck.png,
                                /images/empty-state/ente_duck.png"
                    />
                    <span
                        style={{
                            cursor:
                                !uploadManager.shouldAllowNewUpload() &&
                                'not-allowed',
                        }}>
                        <VerticallyCentered paddingLeft={1} paddingRight={1}>
                            <Button
                                color="accent"
                                onClick={openUploader}
                                disabled={!uploadManager.shouldAllowNewUpload()}
                                sx={{
                                    mt: 1.5,
                                    p: 1,
                                    width: 320,
                                    borderRadius: 0.5,
                                }}>
                                <FlexWrapper
                                    sx={{ gap: 1 }}
                                    justifyContent="center">
                                    <AddPhotoAlternateIcon />
                                    {constants.UPLOAD_FIRST_PHOTO}
                                </FlexWrapper>
                            </Button>
                            <Button
                                sx={{
                                    mt: 1.5,
                                    p: 1,
                                    width: 320,
                                    borderRadius: 0.5,
                                }}>
                                <FlexWrapper
                                    sx={{ gap: 1 }}
                                    justifyContent="center">
                                    <FolderIcon />
                                    {constants.IMPORT_YOUR_FOLDERS}
                                </FlexWrapper>
                            </Button>
                        </VerticallyCentered>
                    </span>
                </>
            )}
        </Wrapper>
    );
}
