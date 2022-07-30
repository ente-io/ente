import React, { useContext } from 'react';
import { Button, styled, Typography } from '@mui/material';
import constants from 'utils/strings/constants';
import { DeduplicateContext } from 'pages/deduplicate';
import VerticallyCentered from './Container';

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
                    <img
                        height={150}
                        src="/images/gallery-locked/1x.png"
                        srcSet="/images/gallery-locked/2x.png 2x,
                                /images/gallery-locked/3x.png 3x"
                    />
                    <Typography color="text.secondary" mt={2}>
                        {constants.UPLOAD_FIRST_PHOTO_DESCRIPTION()}
                    </Typography>

                    <Button
                        color="accent"
                        onClick={openUploader}
                        sx={{ mt: 4 }}>
                        {constants.UPLOAD_FIRST_PHOTO}
                    </Button>
                </>
            )}
        </Wrapper>
    );
}
