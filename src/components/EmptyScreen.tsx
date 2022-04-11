import React, { useContext } from 'react';
import { Button } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import { DeduplicateContext } from 'pages/deduplicate';

const Wrapper = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    flex: 1;
    color: #51cd7c;

    & > svg {
        filter: drop-shadow(3px 3px 5px rgba(45, 194, 98, 0.5));
    }
`;

export default function EmptyScreen({ openFileUploader }) {
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
                    <img height={150} src="/images/gallery.png" />
                    <div style={{ color: '#a6a6a6', marginTop: '16px' }}>
                        {constants.UPLOAD_FIRST_PHOTO_DESCRIPTION}
                    </div>
                    <Button
                        variant="outline-success"
                        onClick={openFileUploader}
                        style={{
                            marginTop: '32px',
                            paddingLeft: '32px',
                            paddingRight: '32px',
                            paddingTop: '12px',
                            paddingBottom: '12px',
                            fontWeight: 900,
                        }}>
                        {constants.UPLOAD_FIRST_PHOTO}
                    </Button>
                </>
            )}
        </Wrapper>
    );
}
