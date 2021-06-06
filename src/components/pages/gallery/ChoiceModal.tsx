import MessageDialog from 'components/MessageDialog';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { UPLOAD_STRATEGY } from './Upload';

interface Props {
    uploadFiles;
    show;
    onHide;
    showCollectionCreateModal;
}
function ChoiceModal({
    uploadFiles,
    showCollectionCreateModal,
    ...props
}: Props) {
    return (
        <MessageDialog
            size="lg"
            {...props}
            attributes={{ title: constants.MULTI_FOLDER_UPLOAD }}
        >
            <p>{constants.UPLOAD_STRATEGY_CHOICE}</p>
            <div
                style={{
                    display: 'flex',
                    flexWrap: 'wrap',
                }}
            >
                <Button
                    variant="outline-success"
                    onClick={() => {
                        props.onHide();
                        showCollectionCreateModal();
                    }}
                    style={{
                        padding: '12px 24px',
                        flex: 2,
                        whiteSpace: 'nowrap',
                    }}
                >
                    {constants.UPLOAD_STRATEGY_SINGLE_COLLECTION}
                </Button>
                <div
                    style={{
                        flex: 1,
                        textAlign: 'center',
                        minWidth: '100px',
                        margin: '2% auto',
                    }}
                >
                    <strong>{constants.OR}</strong>
                </div>
                <Button
                    variant="outline-success"
                    onClick={() => {
                        props.onHide();
                        uploadFiles(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER);
                    }}
                    style={{
                        padding: '12px 24px',
                        flex: 2,
                        whiteSpace: 'nowrap',
                    }}
                >
                    {constants.UPLOAD_STRATEGY_COLLECTION_PER_FOLDER}
                </Button>
            </div>
        </MessageDialog>
    );
}
export default ChoiceModal;
