import EmailShare from './emailShare';
import React from 'react';
import { Collection } from 'types/collection';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
import DialogContent from '@mui/material/DialogContent';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import { t } from 'i18next';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
}

function CollectionShare(props: Props) {
    const handleClose = dialogCloseHandler({
        onClose: props.onClose,
    });

    if (!props.collection) {
        return <></>;
    }

    return (
        <>
            <EnteDrawer anchor="right" open={props.open} onClose={handleClose}>
                <DialogTitleWithCloseButton onClose={handleClose}>
                    {t('SHARE_COLLECTION')}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    <MenuSectionTitle
                        title={t('ADD_EMAIL_TITLE')}
                        icon={<WorkspacesIcon />}
                    />
                    <EmailShare collection={props.collection} />
                    <PublicShare collection={props.collection} />
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
export default CollectionShare;
