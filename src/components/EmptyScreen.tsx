import React, { useContext } from 'react';
import { Button, Stack, styled, Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { DeduplicateContext } from 'pages/deduplicate';
import VerticallyCentered, { FlexWrapper } from './Container';
import { Box } from '@mui/material';
import uploadManager from 'services/upload/uploadManager';
import AddPhotoAlternateIcon from '@mui/icons-material/AddPhotoAlternateOutlined';
import FolderIcon from '@mui/icons-material/FolderOutlined';
import { UploadTypeSelectorIntent } from 'types/gallery';

const Wrapper = styled(Box)`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: top;
    flex-direction: column;
    text-align: center;
    overflow: auto;
    & > svg {
        filter: drop-shadow(3px 3px 5px rgba(45, 194, 98, 0.5));
    }
`;
const NonDraggableImage = styled('img')`
    pointer-events: none;
`;

export default function EmptyScreen({ openUploader }) {
    const deduplicateContext = useContext(DeduplicateContext);
    return deduplicateContext.isOnDeduplicatePage ? (
        <VerticallyCentered>
            <div
                style={{
                    color: '#a6a6a6',
                    fontSize: '18px',
                }}>
                {constants.NO_DUPLICATES_FOUND}
            </div>
        </VerticallyCentered>
    ) : (
        <Wrapper>
            <Stack
                sx={{
                    flex: 'none',
                    pt: 1.5,
                    pb: 1.5,
                }}>
                <VerticallyCentered sx={{ flex: 'none' }}>
                    {constants.WELCOME_TO_ENTE()}
                </VerticallyCentered>
                <Typography variant="body1" mt={3.5} color="text.secondary">
                    {constants.WHERE_YOUR_BEST_PHOTOS_LIVE}
                </Typography>
            </Stack>
            <NonDraggableImage
                height={287.57}
                src="/images/empty-state/ente_duck.png"
                srcSet="/images/empty-state/ente_duck@2x.png,
                                /images/empty-state/ente_duck@3x.png"
            />
            <span
                style={{
                    cursor:
                        !uploadManager.shouldAllowNewUpload() && 'not-allowed',
                }}>
                <VerticallyCentered paddingTop={1.5} paddingBottom={1.5}>
                    <Button
                        color="accent"
                        onClick={() =>
                            openUploader(UploadTypeSelectorIntent.normalUpload)
                        }
                        disabled={!uploadManager.shouldAllowNewUpload()}
                        sx={{
                            mt: 1.5,
                            p: 1,
                            width: 320,
                            borderRadius: 0.5,
                        }}>
                        <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                            <AddPhotoAlternateIcon />
                            {constants.UPLOAD_FIRST_PHOTO}
                        </FlexWrapper>
                    </Button>
                    <Button
                        onClick={() =>
                            openUploader(UploadTypeSelectorIntent.import)
                        }
                        disabled={!uploadManager.shouldAllowNewUpload()}
                        sx={{
                            mt: 1.5,
                            p: 1,
                            width: 320,
                            borderRadius: 0.5,
                        }}>
                        <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                            <FolderIcon />
                            {constants.IMPORT_YOUR_FOLDERS}
                        </FlexWrapper>
                    </Button>
                </VerticallyCentered>
                <VerticallyCentered
                    paddingTop={3}
                    paddingBottom={3}
                    sx={{ gap: 3 }}>
                    <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                        <a href="https://apps.apple.com/app/id1542026904">
                            <NonDraggableImage
                                height={59}
                                src="/images/download_assets/download_app_store.png"
                                srcSet="/images/download_assets/download_app_store@2x.png,
                                /images/download_assets/download_app_store@3x.png"
                            />
                        </a>
                        <a href="https://play.app.goo.gl/?link=https://play.google.com/store/apps/details?id=io.ente.photos">
                            <NonDraggableImage
                                height={59}
                                src="/images/download_assets/download_play_store.png"
                                srcSet="/images/download_assets/download_play_store@2x.png,
                                /images/download_assets/download_play_store@3x.png"
                            />
                        </a>
                    </FlexWrapper>
                    <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                        <a href="https://f-droid.org/packages/io.ente.photos.fdroid/">
                            <NonDraggableImage
                                height={49}
                                src="/images/download_assets/download_fdroid.png"
                                srcSet="/images/download_assets/download_fdroid@2x.png,
                                /images/download_assets/download_fdroid@3x.png"
                                style={{ pointerEvents: 'none' }}
                            />
                        </a>
                        <a href="https://github.com/ente-io">
                            <NonDraggableImage
                                height={49}
                                src="/images/download_assets/download_github.png"
                                srcSet="/images/download_assets/download_github@2x.png,
                                /images/download_assets/download_github@3x.png"
                                style={{ pointerEvents: 'none' }}
                            />
                        </a>
                    </FlexWrapper>
                </VerticallyCentered>
            </span>
        </Wrapper>
    );
}
