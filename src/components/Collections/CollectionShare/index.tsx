import EmailShare from './emailShare';
import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import { Collection } from 'types/collection';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
import DialogContent from '@mui/material/DialogContent';
import { Divider } from '@mui/material';

import { CollectionShareContainer } from './container';
import PublicShare from './publicShare';
import { AppContext } from 'pages/_app';

interface Props {
    open: boolean;
    onClose: () => void;
    collection: Collection;
}

function CollectionShare(props: Props) {
    const { isMobile } = useContext(AppContext);
    const handleClose = dialogCloseHandler({
        onClose: props.onClose,
    });

    if (!props.collection) {
        return <></>;
    }

    return (
        <>
            <CollectionShareContainer
                open={props.open}
                onClose={handleClose}
                fullScreen={isMobile}>
                <DialogTitleWithCloseButton onClose={handleClose}>
                    {constants.SHARE_COLLECTION}
                </DialogTitleWithCloseButton>
                <DialogContent>
                    <EmailShare collection={props.collection} />
                    <Divider />
                    <PublicShare collection={props.collection} />
                </DialogContent>
            </CollectionShareContainer>
        </>
    );
}
export default CollectionShare;
