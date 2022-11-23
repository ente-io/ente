import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import CryptoWorker, { B64EncryptionResult } from 'utils/crypto';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import VerticallyCentered from 'components/Container';
import { logError } from 'utils/sentry';
import { recoverTwoFactor, removeTwoFactor } from 'services/userService';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
const bip39 = require('bip39');
// mobile client library only supports english.
bip39.setDefaultWordlist('english');

export default function Recover() {
    const router = useRouter();
    const [encryptedTwoFactorSecret, setEncryptedTwoFactorSecret] =
        useState<B64EncryptionResult>(null);
    const [sessionID, setSessionID] = useState(null);
    const appContext = useContext(AppContext);

    useEffect(() => {
        router.prefetch(PAGES.GALLERY);
        const user = getData(LS_KEYS.USER);
        if (!user.isTwoFactorEnabled && (user.encryptedToken || user.token)) {
            router.push(PAGES.GENERATE);
        } else if (!user.email || !user.twoFactorSessionID) {
            router.push(PAGES.ROOT);
        } else {
            setSessionID(user.twoFactorSessionID);
        }
        const main = async () => {
            const resp = await recoverTwoFactor(user.twoFactorSessionID);
            setEncryptedTwoFactorSecret({
                encryptedData: resp.encryptedSecret,
                nonce: resp.secretDecryptionNonce,
                key: null,
            });
        };
        main();
    }, []);

    const recover: SingleInputFormProps['callback'] = async (
        recoveryKey: string,
        setFieldError
    ) => {
        try {
            // check if user is entering mnemonic recovery key
            if (recoveryKey.trim().indexOf(' ') > 0) {
                if (recoveryKey.trim().split(' ').length !== 24) {
                    throw new Error('recovery code should have 24 words');
                }
                recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
            }
            const cryptoWorker = await new CryptoWorker();
            const twoFactorSecret: string = await cryptoWorker.decryptB64(
                encryptedTwoFactorSecret.encryptedData,
                encryptedTwoFactorSecret.nonce,
                await cryptoWorker.fromHex(recoveryKey)
            );
            const resp = await removeTwoFactor(sessionID, twoFactorSecret);
            const { keyAttributes, encryptedToken, token, id } = resp;
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
                isTwoFactorEnabled: false,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            logError(e, 'two factor recovery failed');
            setFieldError(constants.INCORRECT_RECOVERY_KEY);
        }
    };

    const showNoRecoveryKeyMessage = () => {
        appContext.setDialogMessage({
            title: constants.CONTACT_SUPPORT,
            close: {},
            content: constants.NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE(),
        });
    };

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{constants.RECOVER_TWO_FACTOR}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={constants.RECOVERY_KEY_HINT}
                    buttonText={constants.RECOVER}
                />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton onClick={showNoRecoveryKeyMessage}>
                        {constants.NO_RECOVERY_KEY}
                    </LinkButton>
                    <LinkButton onClick={router.back}>
                        {constants.GO_BACK}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
