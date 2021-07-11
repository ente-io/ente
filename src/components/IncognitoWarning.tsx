import React from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';

export default function IncognitoWarning() {
    return (
        <MessageDialog
            show={true}
            onHide={() => null}
            attributes={{
                title: constants.LOCAL_STORAGE_NOT_ACCESSIBLE,
                staticBackdrop: true,
                nonClosable: true,
            }}
        >
            <div>
                {constants.LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE}
            </div>
        </MessageDialog>
    );
}
