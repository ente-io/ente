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
    console.log(props.show);
    return (
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
        >
            <Modal.Body style={{ padding: '24px' }}>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants.UPLOAD_STRATEGY_CHOICE}
                </Modal.Title>
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button
                    variant="success"
                    onClick={() => {
                        props.onHide();
                        showCollectionCreateModal();
                    }}
                >
                    {constants.UPLOAD_STRATEGY_SINGLE_COLLECTION}
                </Button>
                <Button
                    variant="success"
                    onClick={() =>
                        uploadFiles(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER)
                    }
                >
                    {constants.UPLOAD_STRATEGY_COLLECTION_PER_FOLDER}
                </Button>
                <Button variant="secondary" onClick={props.onHide}>
                    {constants.CANCEL}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default ChoiceModal;
