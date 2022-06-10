import EmailShare from './emailShare';
import React from 'react';
import constants from 'utils/strings/constants';
import { Collection } from 'types/collection';
import { dialogCloseHandler } from 'components/DialogBox/base';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';
import DialogContent from '@mui/material/DialogContent';
import { Divider } from '@mui/material';

import { CollectionShareContainer } from './container';
import PublicShare from './publicShare';

interface Props {
    show: boolean;
    onHide: () => void;
    collection: Collection;
}

function CollectionShare(props: Props) {
    const handleClose = dialogCloseHandler({
        onClose: props.onHide,
    });

    if (!props.collection) {
        return <></>;
    }

    return (
        <>
            <CollectionShareContainer open={props.show} onClose={handleClose}>
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
