import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import CryptoWorker, { B64EncryptionResult } from 'utils/crypto';
import SingleInputForm from 'components/SingleInputForm';
import MessageDialog from 'components/MessageDialog';
import Container from 'components/Container';
import { Card, Button } from 'react-bootstrap';
import LogoImg from 'components/LogoImg';
import { logError } from 'utils/sentry';
import { recoverTwoFactor, removeTwoFactor } from 'services/userService';
import { AppContext, FLASH_MESSAGE_TYPE } from 'pages/_app';
import { PAGES } from 'types';

export default function Recover() {
    const router = useRouter();
    const [messageDialogView, SetMessageDialogView] = useState(false);
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

    const recover = async (recoveryKey: string, setFieldError) => {
        try {
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
            appContext.setDisappearingFlashMessage({
                message: constants.TWO_FACTOR_DISABLE_SUCCESS,
                type: FLASH_MESSAGE_TYPE.INFO,
            });
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            logError(e);
            setFieldError('passphrase', constants.INCORRECT_RECOVERY_KEY);
        }
    };

    return (
        <>
            <Container>
                <Card style={{ minWidth: '320px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src="/icon.svg" />
                            {constants.RECOVER_TWO_FACTOR}
                        </Card.Title>
                        <SingleInputForm
                            callback={recover}
                            fieldType="text"
                            placeholder={constants.RETURN_RECOVERY_KEY_HINT}
                            buttonText={constants.RECOVER}
                        />
                        <div
                            style={{
                                display: 'flex',
                                flexDirection: 'column',
                                marginTop: '12px',
                            }}>
                            <Button
                                variant="link"
                                onClick={() => SetMessageDialogView(true)}>
                                {constants.NO_RECOVERY_KEY}
                            </Button>
                            <Button variant="link" onClick={router.back}>
                                {constants.GO_BACK}
                            </Button>
                        </div>
                    </Card.Body>
                </Card>
            </Container>
            <MessageDialog
                size="lg"
                show={messageDialogView}
                onHide={() => SetMessageDialogView(false)}
                attributes={{
                    title: constants.CONTACT_SUPPORT,
                    close: {},
                    content: constants.NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE(),
                }}
            />
        </>
    );
}
