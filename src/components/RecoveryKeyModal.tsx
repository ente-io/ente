import React, { useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { getRecoveryKey } from 'utils/crypto';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import EnteSpinner from './EnteSpinner';
import styled from 'styled-components';

export const CodeBlock = styled.div<{ height: number }>`
    display: flex;
    align-items: center;
    justify-content: center;
    background: #1a1919;
    height: ${(props) => props.height}px;
    padding-left:30px;
    padding-right:20px;
    color: white;
    margin: 20px 0;
`;

export const FreeFlowText = styled.div`
    word-wrap: break-word;
    overflow-wrap: break-word;
    min-width: 30%;
`;
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
            setRecoveryKey(recoveryKey);
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
            }}
        >
            <p>{constants.RECOVERY_KEY_DESCRIPTION}</p>
            <CodeBlock height={150}>
                {recoveryKey ? (
                    <FreeFlowText>
                        {recoveryKey}
                    </FreeFlowText>
                ) : (
                    <EnteSpinner />
                )}
            </CodeBlock>
            <p>{constants.KEY_NOT_STORED_DISCLAIMER}</p>
        </MessageDialog >
    );
}
export default RecoveryKeyModal;
