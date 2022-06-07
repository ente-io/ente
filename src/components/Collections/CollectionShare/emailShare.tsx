import SingleInputForm from 'components/SingleInputForm';
import { GalleryContext } from 'pages/gallery';
import React, { useContext } from 'react';
import { shareCollection } from 'services/collectionService';
import { User } from 'types/user';
import { sleep } from 'utils/common';
import { handleSharingErrors } from 'utils/error';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import { CollectionShareSharees } from './sharees';
import CollectionShareSubmitButton from './submitButton';
export default function EmailShare({ collection }) {
    const galleryContext = useContext(GalleryContext);

    const collectionShare = async (email, setFieldError) => {
        try {
            const user: User = getData(LS_KEYS.USER);
            if (email === user.email) {
                setFieldError('email', constants.SHARE_WITH_SELF);
            } else if (
                collection?.sharees?.find((value) => value.email === email)
            ) {
                setFieldError('email', constants.ALREADY_SHARED(email));
            } else {
                await shareCollection(collection, email);
                await sleep(2000);
                await galleryContext.syncWithRemote(false, true);
            }
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setFieldError('email', errorMessage);
        }
    };
    return (
        <>
            <SingleInputForm
                callback={collectionShare}
                placeholder={constants.ENTER_EMAIL}
                fieldType="email"
                buttonText={constants.SHARE}
                customSubmitButton={CollectionShareSubmitButton}
            />
            <CollectionShareSharees collection={collection} />
        </>
    );
}
