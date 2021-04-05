import React, { useEffect, useState } from 'react';
import { Button, Modal, Spinner } from 'react-bootstrap';
import { downloadAsFile } from 'utils/common';
import { getRecoveryKey } from 'utils/crypto';
import constants from 'utils/strings/constants';

export interface Props {
    show: boolean;
    onHide: () => void;
}
function RecoveryKeyModal(props: Props) {
    const [recoveryKey, setRecoveryKey] = useState(null);
    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            const recoveryKey = await getRecoveryKey();

            setRecoveryKey(recoveryKey);
        };
        main();
    }, [props.show]);

    return (
        <Modal {...props} size="lg" centered>
            <Modal.Body>
                <Modal.Title>
                    <strong>{constants.DOWNLOAD_RECOVERY_KEY}</strong>
                </Modal.Title>
                <hr />
                {constants.PASSPHRASE_DISCLAIMER()}
                <div
                    style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        background: '#1a1919',
                        height: '150px',
                        padding: '40px',
                        color: 'white',
                        margin: '20px 0',
                    }}
                >
                    {recoveryKey ? (
                        <div
                            style={{
                                wordWrap: 'break-word',
                                overflowWrap: 'break-word',
                                minWidth: '40%',
                            }}
                        >
                            {recoveryKey}
                        </div>
                    ) : (
                        <Spinner animation="border" />
                    )}
                </div>
                {constants.KEY_NOT_STORED_DISCLAIMER()}
            </Modal.Body>
            <Modal.Footer style={{ borderTop: 'none' }}>
                <Button variant="danger" onClick={props.onHide}>
                    {constants.SAVE_LATER}
                </Button>
                <Button
                    variant="success"
                    onClick={() =>
                        downloadAsFile(
                            constants.RECOVERY_KEY_FILENAME,
                            recoveryKey
                        )
                    }
                >
                    {constants.SAVE}
                </Button>
            </Modal.Footer>
        </Modal>
    );
}
export default RecoveryKeyModal;
