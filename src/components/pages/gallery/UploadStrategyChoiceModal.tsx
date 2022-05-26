import { Button, DialogContent } from '@mui/material';
import { CenteredFlex, SpaceBetweenFlex } from 'components/Container';
import DialogBoxBase, { dialogCloseHandler } from 'components/DialogBox/base';
import MessageText from 'components/DialogBox/messageText';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';
import React from 'react';
import constants from 'utils/strings/constants';

interface Props {
    uploadToMultipleCollection: () => void;
    open: boolean;
    onClose: () => void;
    uploadToSingleCollection: () => void;
}
function UploadStrategyChoiceModal({
    uploadToMultipleCollection,
    uploadToSingleCollection,
    ...props
}: Props) {
    const handleClose = dialogCloseHandler({
        staticBackdrop: true,
        onClose: props.onClose,
    });

    return (
        <DialogBoxBase open={props.open} onClose={handleClose}>
            <DialogTitleWithCloseButton onClose={handleClose}>
                {constants.MULTI_FOLDER_UPLOAD}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <CenteredFlex mb={1}>
                    <MessageText>
                        {constants.UPLOAD_STRATEGY_CHOICE}
                    </MessageText>
                </CenteredFlex>
                <SpaceBetweenFlex>
                    <Button
                        size="large"
                        color="accent"
                        onClick={() => {
                            props.onClose();
                            uploadToSingleCollection();
                        }}>
                        {constants.UPLOAD_STRATEGY_SINGLE_COLLECTION}
                    </Button>

                    <strong>{constants.OR}</strong>

                    <Button
                        size="large"
                        color="accent"
                        onClick={() => {
                            props.onClose();
                            uploadToMultipleCollection();
                        }}>
                        {constants.UPLOAD_STRATEGY_COLLECTION_PER_FOLDER}
                    </Button>
                </SpaceBetweenFlex>
            </DialogContent>
        </DialogBoxBase>
    );
}
export default UploadStrategyChoiceModal;
