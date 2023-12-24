import { CenteredFlex } from '@ente/shared/components/Container';
import SingleInputForm from '@ente/shared/components/SingleInputForm';
import { Box } from '@mui/material';
import {
    finishPasskeyRegistration,
    getPasskeyRegistrationOptions,
} from '../../services/passkeysService';
import { logError } from '@ente/shared/sentry';
import _sodium from 'libsodium-wrappers';
import { Dispatch, SetStateAction, createContext, useState } from 'react';
import { Passkey } from 'types/passkey';
import PasskeysList from './PasskeysList';
import ManagePasskeyDrawer from './ManagePasskeyDrawer';
import { t } from 'i18next';

export const PasskeysContext = createContext(
    {} as {
        selectedPasskey: Passkey | null;
        setSelectedPasskey: Dispatch<SetStateAction<Passkey | null>>;
        setShowPasskeyDrawer: Dispatch<SetStateAction<boolean>>;
    }
);

const Passkeys = () => {
    const [selectedPasskey, setSelectedPasskey] = useState<Passkey | null>(
        null
    );

    const [showPasskeyDrawer, setShowPasskeyDrawer] = useState(false);

    const handleSubmit = async (inputValue: string) => {
        const response: {
            options: {
                publicKey: PublicKeyCredentialCreationOptions;
            };
            sessionID: string;
        } = await getPasskeyRegistrationOptions();

        const options = response.options;

        options.publicKey.challenge = _sodium.from_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            options.publicKey.challenge
        );
        options.publicKey.user.id = _sodium.from_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            options.publicKey.user.id
        );

        // create new credential
        let newCredential: Credential;

        try {
            newCredential = await navigator.credentials.create(options);
        } catch (e) {
            return logError(e, 'Error creating credential');
        }

        await finishPasskeyRegistration(
            inputValue,
            newCredential,
            response.sessionID
        );
    };

    return (
        <>
            <PasskeysContext.Provider
                value={{
                    selectedPasskey,
                    setSelectedPasskey,
                    setShowPasskeyDrawer,
                }}>
                <CenteredFlex>
                    <Box>
                        <SingleInputForm
                            fieldType="text"
                            placeholder={t('ENTER_PASSKEY_NAME')}
                            buttonText={t('ADD_PASSKEY')}
                            initialValue={''}
                            blockButton
                            callback={handleSubmit}
                        />
                        <Box>
                            <PasskeysList />
                        </Box>
                    </Box>
                </CenteredFlex>
                <ManagePasskeyDrawer open={showPasskeyDrawer} />
            </PasskeysContext.Provider>
        </>
    );
};

export default Passkeys;
