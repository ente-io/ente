import EmailShare from './emailShare';
import React from 'react';
import { Collection } from 'types/collection';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
import DialogContent from '@mui/material/DialogContent';
import { Typography } from '@mui/material';
import { EnteDrawer } from 'components/EnteDrawer';
import PublicShare from './publicShare';
import WorkspacesIcon from '@mui/icons-material/Workspaces';
import { t } from 'i18next';

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
                    <Typography color="text.secondary" variant="body2">
                        <WorkspacesIcon
                            style={{ fontSize: 17, marginRight: 8 }}
                        />
                        {t('ADD_EMAIL_TITLE')}
                    </Typography>
                    <EmailShare collection={props.collection} />
                    <PublicShare collection={props.collection} />
                </DialogContent>
            </EnteDrawer>
        </>
    );
}
export default CollectionShare;
