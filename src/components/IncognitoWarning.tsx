import React from 'react';
import constants from 'utils/strings/constants';
import DialogBox from './DialogBox';

export default function IncognitoWarning() {
    return (
        <DialogBox
            show={true}
            onHide={() => null}
            attributes={{
                title: constants.LOCAL_STORAGE_NOT_ACCESSIBLE,
                staticBackdrop: true,
                nonClosable: true,
            }}>
            <div>{constants.LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE}</div>
        </DialogBox>
    );
}
