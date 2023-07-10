import { GalleryContext } from 'pages/gallery';
import React, { useContext, useState, useEffect } from 'react';
import { t } from 'i18next';
import { shareCollection } from 'services/collectionService';
import { User } from 'types/user';
import { handleSharingErrors } from 'utils/error/ui';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
// import { CollectionShareSharees } from './sharees';
import { getLocalCollections } from 'services/collectionService';
import { getLocalFamilyData } from 'utils/user/family';
import CollabEmailShareOptions, {
    CollabEmailShareOptionsProps,
} from './CollabEmailShareOptions';

export default function CollabEmailShare({ collection, onClose }) {
    const galleryContext = useContext(GalleryContext);

    const [updatedOptionsList, setUpdatedOptionsList] = useState(['']);
    let updatedList = [];
    useEffect(() => {
        const getUpdatedOptionsList = async () => {
            const ownerUser: User = getData(LS_KEYS.USER);
            const collectionList = getLocalCollections();
            const familyList = getLocalFamilyData();
            const result = await collectionList;
            const emails = result.flatMap((item) => {
                if (item.owner.email && item.owner.id !== ownerUser.id) {
                    return [item.owner.email];
                } else {
                    const shareeEmails = item.sharees.map(
                        (sharee) => sharee.email
                    );
                    return shareeEmails;
                }
            });

            // adding family members
            if (familyList) {
                const family = familyList.members.map((member) => member.email);
                emails.push(...family);
            }

            updatedList = Array.from(new Set(emails));

            const shareeEmailsCollection = collection.sharees.map(
                (sharees) => sharees.email
            );
            const filteredList = updatedList.filter(
                (email) =>
                    !shareeEmailsCollection.includes(email) &&
                    email !== ownerUser.email
            );

            setUpdatedOptionsList(filteredList);
        };

        getUpdatedOptionsList();
    }, []);

    const collectionShare: CollabEmailShareOptionsProps['callback'] = async (
        emails,
        setFieldError,
        resetForm
    ) => {
        try {
            const user: User = getData(LS_KEYS.USER);

            for (const email of emails) {
                if (email === user.email) {
                    setFieldError(t('SHARE_WITH_SELF'));
                    break;
                } else if (
                    collection?.sharees?.find((value) => value.email === email)
                ) {
                    setFieldError(t('ALREADY_SHARED', { email }));
                    break;
                } else {
                    await shareCollection(collection, email, 'COLLABORATOR');
                    await galleryContext.syncWithRemote(false, true);
                    resetForm();
                }
            }
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setFieldError(errorMessage);
        }
    };

    return (
        <>
            <CollabEmailShareOptions
                onClose={onClose}
                callback={collectionShare}
                optionsList={updatedOptionsList}
                placeholder={t('ENTER_EMAIL')}
                fieldType="email"
                buttonText={t('Add Collaborator')}
                submitButtonProps={{
                    size: 'large',
                    sx: { mt: 1, mb: 2 },
                }}
                disableAutoFocus
            />
            {/* <CollectionShareSharees collection={collection} /> */}
        </>
    );
}
