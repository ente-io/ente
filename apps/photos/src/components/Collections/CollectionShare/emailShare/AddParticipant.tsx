import { Stack } from '@mui/material';
import { COLLECTION_ROLE, Collection } from 'types/collection';
import { EnteDrawer } from 'components/EnteDrawer';
import { t } from 'i18next';
import { DialogProps } from '@mui/material';
import Titlebar from 'components/Titlebar';

import { GalleryContext } from 'pages/gallery';
import { useContext, useMemo } from 'react';
import { shareCollection } from 'services/collectionService';
import { handleSharingErrors } from 'utils/error/ui';
import AddParticipantForm, {
    AddParticipantFormProps,
} from './AddParticipantForm';

interface Iprops {
    collection: Collection;
    open: boolean;
    onClose: () => void;
    onRootClose: () => void;
    type: COLLECTION_ROLE.VIEWER | COLLECTION_ROLE.COLLABORATOR;
}

export default function AddParticipant({
    open,
    collection,
    onClose,
    onRootClose,
    type,
}: Iprops) {
    const { user, syncWithRemote, emailList } = useContext(GalleryContext);

    const nonSharedEmails = useMemo(
        () =>
            emailList.filter(
                (email) =>
                    !collection.sharees?.find((value) => value.email === email)
            ),
        [emailList, collection.sharees]
    );

    const collectionShare: AddParticipantFormProps['callback'] = async (
        emails,
        setFieldError,
        resetForm
    ) => {
        try {
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
                    await shareCollection(collection, email, type);
                    await syncWithRemote(false, true);
                }
            }
            resetForm();
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setFieldError(errorMessage);
        }
    };

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps['onClose'] = (_, reason) => {
        if (reason === 'backdropClick') {
            handleRootClose();
        } else {
            onClose();
        }
    };

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={handleDrawerClose}>
                <Stack spacing={'4px'} py={'12px'}>
                    <Titlebar
                        onClose={onClose}
                        title={
                            type === COLLECTION_ROLE.VIEWER
                                ? t('ADD_VIEWERS')
                                : t('ADD_COLLABORATORS')
                        }
                        onRootClose={handleRootClose}
                        caption={collection.name}
                    />
                    <AddParticipantForm
                        onClose={onClose}
                        callback={collectionShare}
                        optionsList={nonSharedEmails}
                        placeholder={t('ENTER_EMAIL')}
                        fieldType="email"
                        buttonText={
                            type === COLLECTION_ROLE.VIEWER
                                ? t('ADD_VIEWERS')
                                : t('ADD_COLLABORATORS')
                        }
                        submitButtonProps={{
                            size: 'large',
                            sx: { mt: 1, mb: 2 },
                        }}
                        disableAutoFocus
                    />
                </Stack>
            </EnteDrawer>
        </>
    );
}
