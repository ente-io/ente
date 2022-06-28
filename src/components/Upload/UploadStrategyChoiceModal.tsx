import { Button, Dialog, DialogContent, Typography } from '@mui/material';
import { CenteredFlex, SpaceBetweenFlex } from 'components/Container';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
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
        onClose: props.onClose,
    });

    return (
        <Dialog open={props.open} onClose={handleClose}>
            <DialogTitleWithCloseButton onClose={handleClose}>
                {constants.MULTI_FOLDER_UPLOAD}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <CenteredFlex mb={1}>
                    <Typography color="text.secondary">
                        {constants.UPLOAD_STRATEGY_CHOICE}
                    </Typography>
                </CenteredFlex>
                <SpaceBetweenFlex px={2}>
                    <Button
                        size="medium"
                        color="accent"
                        onClick={() => {
                            props.onClose();
                            uploadToSingleCollection();
                        }}>
                        {constants.UPLOAD_STRATEGY_SINGLE_COLLECTION}
                    </Button>

                    <strong>{constants.OR}</strong>

                    <Button
                        size="medium"
                        color="accent"
                        onClick={() => {
                            props.onClose();
                            uploadToMultipleCollection();
                        }}>
                        {constants.UPLOAD_STRATEGY_COLLECTION_PER_FOLDER}
                    </Button>
                </SpaceBetweenFlex>
            </DialogContent>
        </Dialog>
    );
}
export default UploadStrategyChoiceModal;
