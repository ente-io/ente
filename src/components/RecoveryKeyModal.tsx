import React, { useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { getRecoveryKey } from 'utils/crypto';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { CodeBlock } from './CodeBlock';
const bip39 = require('bip39');
// mobile client library only supports english.
bip39.setDefaultWordlist('english');

interface Props {
    show: boolean;
    onHide: () => void;
    somethingWentWrong: any;
}
function RecoveryKeyModal({ somethingWentWrong, ...props }: Props) {
    const [recoveryKey, setRecoveryKey] = useState(null);
    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            const recoveryKey = await getRecoveryKey();
            if (!recoveryKey) {
                somethingWentWrong();
                props.onHide();
            }
            setRecoveryKey(bip39.entropyToMnemonic(recoveryKey));
        };
        main();
    }, [props.show]);

    function onSaveClick() {
        downloadAsFile(constants.RECOVERY_KEY_FILENAME, recoveryKey);
        onClose();
    }
    function onClose() {
        props.onHide();
    }
    return (
        <MessageDialog
            show={props.show}
            onHide={onClose}
            size="lg"
            attributes={{
                title: constants.DOWNLOAD_RECOVERY_KEY,
                close: {
                    text: constants.SAVE_LATER,
                    variant: 'danger',
                },
                staticBackdrop: true,
                proceed: {
                    text: constants.SAVE,
                    action: onSaveClick,
                    disabled: !recoveryKey,
                    variant: 'success',
                },
            }}>
            <p>{constants.RECOVERY_KEY_DESCRIPTION}</p>
            <CodeBlock height={'150px'} code={recoveryKey} />
            <p>{constants.KEY_NOT_STORED_DISCLAIMER}</p>
        </MessageDialog>
    );
}
export default RecoveryKeyModal;
