import React, { useEffect, useState } from 'react';
import { Spinner } from 'react-bootstrap';
import { downloadAsFile } from 'utils/common';
import { getRecoveryKey } from 'utils/crypto';
import constants from 'utils/strings/constants';
import { MessageDialog } from './MessageDailog';

interface Props {
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
            const recoveryKey = null; //await getRecoveryKey();

            setRecoveryKey(recoveryKey);
        };
        main();
    }, [props.show]);

    return (
        <MessageDialog
            {...props}
            attributes={{
                title: constants.DOWNLOAD_RECOVERY_KEY,
                cancel: { text: constants.SAVE_LATER },
                proceed: {
                    text: constants.SAVE,
                    action: () => {
                        downloadAsFile(
                            constants.RECOVERY_KEY_FILENAME,
                            recoveryKey
                        );
                        props.onHide();
                    },
                },
            }}
        >
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
        </MessageDialog>
    );
}
export default RecoveryKeyModal;
