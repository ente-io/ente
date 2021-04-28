import React from 'react';
import { Button, Modal } from 'react-bootstrap';
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
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Header
                    style={{
                        borderColor: 'rgb(16, 176, 2)',
                        fontSize: '20px',
                        marginBottom: '20px',
                        border: 'none',
                    }}
                    id="contained-modal-title-vcenter"
                    closeButton
                >
                    {constants.UPLOAD_STRATEGY_CHOICE}
                </Modal.Header>
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-around',
                        paddingBottom: '20px',
                        alignItems: 'center',
                    }}
                >
                    <Button
                        variant="outline-success"
                        onClick={() => {
                            props.onHide();
                            showCollectionCreateModal();
                        }}
                        style={{
                            padding: '12px',
                            paddingLeft: '24px',
                            paddingRight: '24px',
                        }}
                    >
                        {constants.UPLOAD_STRATEGY_SINGLE_COLLECTION}
                    </Button>
                    <strong>{constants.OR}</strong>
                    <Button
                        variant="outline-success"
                        onClick={() =>
                            uploadFiles(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER)
                        }
                        style={{
                            padding: '12px',
                            paddingLeft: '24px',
                            paddingRight: '24px',
                        }}
                    >
                        {constants.UPLOAD_STRATEGY_COLLECTION_PER_FOLDER}
                    </Button>
                </div>
            </Modal.Body>
        </Modal>
    );
}
export default ChoiceModal;
