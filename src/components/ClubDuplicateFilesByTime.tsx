import { GalleryContext } from 'pages/gallery';
import React, { useContext } from 'react';
import styled from 'styled-components';
import constants from 'utils/strings/constants';

const Wrapper = styled.div`
    position: fixed;
    display: flex;
    align-items: center;
    justify-content: center;
    top: 0;
    z-index: 1002;
    min-height: 64px;
    right: 64px;
`;

export default function ClubDuplicateFilesByTime() {
    const galleryContext = useContext(GalleryContext);
    return (
        <Wrapper>
            <input
                type="checkbox"
                style={{
                    width: '1em',
                    height: '1em',
                }}
                value={galleryContext.clubSameTimeFilesOnly ? 'true' : 'false'}
                onChange={() => {
                    galleryContext.setClubSameTimeFilesOnly(
                        !galleryContext.clubSameTimeFilesOnly
                    );
                }}></input>
            <div
                style={{
                    marginLeft: '0.5em',
                    fontSize: '16px',
                    marginRight: '0.8em',
                }}>
                {constants.CLUB_BY_CAPTURE_TIME}
            </div>
        </Wrapper>
    );
}
