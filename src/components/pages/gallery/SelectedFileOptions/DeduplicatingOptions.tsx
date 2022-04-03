import { IconButton } from 'components/Container';
import { GalleryContext } from 'pages/gallery';
import { IconWithMessage } from '.';
import constants from 'utils/strings/constants';
import DeleteIcon from 'components/icons/DeleteIcon';
import React, { useContext } from 'react';

export default function DeduplicatingOptions({ trashHandler }) {
    const galleryContext = useContext(GalleryContext);
    return (
        <>
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
            <div className="vertical-line">
                <div
                    style={{
                        position: 'absolute',
                        width: '1px',
                        top: 0,
                        bottom: 0,
                        background: '#303030',
                    }}></div>
            </div>
            <IconWithMessage message={constants.DELETE}>
                <IconButton onClick={trashHandler}>
                    <DeleteIcon />
                </IconButton>
            </IconWithMessage>
        </>
    );
}
