import React, { useContext, useEffect, useState } from 'react';
import { downloadAsFile } from 'utils/file';
import { getRecoveryKey } from 'utils/crypto';
import CodeBlock from '../CodeBlock';
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    Typography,
} from '@mui/material';
import * as bip39 from 'bip39';
import { DashedBorderWrapper } from './styledComponents';
import { AppContext } from 'pages/_app';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { t } from 'i18next';

// mobile client library only supports english.
bip39.setDefaultWordlist('english');

const RECOVERY_KEY_FILE_NAME = 'ente-recovery-key.txt';

interface Props {
    show: boolean;
    onHide: () => void;
    somethingWentWrong: any;
}

function RecoveryKey({ somethingWentWrong, ...props }: Props) {
    const appContext = useContext(AppContext);
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
        downloadAsFile(RECOVERY_KEY_FILE_NAME, recoveryKey);
        props.onHide();
    }

    return (
        <Dialog
            fullScreen={appContext.isMobile}
            open={props.show}
            onClose={props.onHide}
            maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t('RECOVERY_KEY')}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Typography mb={3}>{t('RECOVERY_KEY_DESCRIPTION')}</Typography>
                <DashedBorderWrapper>
                    <CodeBlock code={recoveryKey} />
                    <Typography m={2}>
                        {t('KEY_NOT_STORED_DISCLAIMER')}
                    </Typography>
                </DashedBorderWrapper>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" size="large" onClick={props.onHide}>
                    {t('SAVE_LATER')}
                </Button>
                <Button color="accent" size="large" onClick={onSaveClick}>
                    {t('SAVE')}
                </Button>
            </DialogActions>
        </Dialog>
    );
}
export default RecoveryKey;
