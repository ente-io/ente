import React, { useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { getRecoveryKey } from 'utils/crypto';
import constants from 'utils/strings/constants';
import DialogBox from '../DialogBox';
import CodeBlock from '../CodeBlock';
import { ButtonProps, Typography } from '@mui/material';
import * as bip39 from 'bip39';
import { DashedBorderWrapper } from './styledComponents';

// mobile client library only supports english.
bip39.setDefaultWordlist('english');

interface Props {
    show: boolean;
    onHide: () => void;
    somethingWentWrong: any;
}

function RecoveryKey({ somethingWentWrong, ...props }: Props) {
    const [recoveryKey, setRecoveryKey] = useState(null);
    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            try {
                const recoveryKey = await getRecoveryKey();
                setRecoveryKey(bip39.entropyToMnemonic(recoveryKey));
            } catch (e) {
                somethingWentWrong();
                props.onHide();
            }
        };
        main();
    }, [props.show]);

    function onSaveClick() {
        downloadAsFile(constants.RECOVERY_KEY_FILENAME, recoveryKey);
        props.onHide();
    }

    const recoveryKeyDialogAttributes = {
        title: constants.RECOVERY_KEY,
        close: {
            text: constants.SAVE_LATER,
            variant: 'secondary' as ButtonProps['color'],
        },
        staticBackdrop: true,
        proceed: {
            text: constants.SAVE,
            action: onSaveClick,
            disabled: !recoveryKey,
            variant: 'accent' as ButtonProps['color'],
        },
    };

    return (
        <DialogBox
            open={props.show}
            onClose={props.onHide}
            size="sm"
            attributes={recoveryKeyDialogAttributes}>
            <Typography mb={3}>{constants.RECOVERY_KEY_DESCRIPTION}</Typography>
            <DashedBorderWrapper>
                <CodeBlock code={recoveryKey} />
                <Typography m={2}>
                    {constants.KEY_NOT_STORED_DISCLAIMER}
                </Typography>
            </DashedBorderWrapper>
        </DialogBox>
    );
}
export default RecoveryKey;
