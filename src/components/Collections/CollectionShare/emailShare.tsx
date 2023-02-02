import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { GalleryContext } from 'pages/gallery';
import React, { useContext } from 'react';
import { shareCollection } from 'services/collectionService';
import { User } from 'types/user';
import { handleSharingErrors } from 'utils/error/ui';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import { CollectionShareSharees } from './sharees';

export default function EmailShare({ collection }) {
    const galleryContext = useContext(GalleryContext);

    const collectionShare: SingleInputFormProps['callback'] = async (
        email,
        setFieldError,
        resetForm
    ) => {
        try {
            const user: User = getData(LS_KEYS.USER);
            if (email === user.email) {
                setFieldError(constants.SHARE_WITH_SELF);
            } else if (
                collection?.sharees?.find((value) => value.email === email)
            ) {
                setFieldError(constants.ALREADY_SHARED(email));
            } else {
                await shareCollection(collection, email);
                await galleryContext.syncWithRemote(false, true);
                resetForm();
            }
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setFieldError(errorMessage);
        }
    };
    return (
        <>
            <SingleInputForm
                callback={collectionShare}
                placeholder={constants.ENTER_EMAIL}
                fieldType="email"
                buttonText={constants.SHARE}
                submitButtonProps={{
                    size: 'medium',
                    sx: { mt: 1, mb: 2 },
                }}
                disableAutoFocus
            />
            <CollectionShareSharees collection={collection} />
        </>
    );
}
