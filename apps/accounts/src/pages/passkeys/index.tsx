import { CenteredFlex } from '@ente/shared/components/Container';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import SingleInputForm from '@ente/shared/components/SingleInputForm';
import { ACCOUNTS_PAGES } from '@ente/shared/constants/pages';
import { logError } from '@ente/shared/sentry';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { Box, Typography } from '@mui/material';
import { t } from 'i18next';
import _sodium from 'libsodium-wrappers';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import {
    Dispatch,
    SetStateAction,
    createContext,
    useContext,
    useEffect,
    useState,
} from 'react';
import { Passkey } from 'types/passkey';
import {
    finishPasskeyRegistration,
    getPasskeyRegistrationOptions,
    getPasskeys,
} from '../../services/passkeysService';
import ManagePasskeyDrawer from './ManagePasskeyDrawer';
import PasskeysList from './PasskeysList';

export const PasskeysContext = createContext(
    {} as {
        selectedPasskey: Passkey | null;
        setSelectedPasskey: Dispatch<SetStateAction<Passkey | null>>;
        setShowPasskeyDrawer: Dispatch<SetStateAction<boolean>>;
        refreshPasskeys: () => void;
    }
);

const Passkeys = () => {
    const { showNavBar } = useContext(AppContext);

    const [selectedPasskey, setSelectedPasskey] = useState<Passkey | null>(
        null
    );

    const [showPasskeyDrawer, setShowPasskeyDrawer] = useState(false);

    const [passkeys, setPasskeys] = useState<Passkey[]>([]);

    const router = useRouter();

    const checkLoggedIn = () => {
        const token = getToken();
        if (!token) {
            router.push(ACCOUNTS_PAGES.LOGIN);
        }
    };

    const init = async () => {
        checkLoggedIn();
        const data = await getPasskeys();
        setPasskeys(data.passkeys || []);
    };

    useEffect(() => {
        showNavBar(true);
        init();
    }, []);

    const handleSubmit = async (
        inputValue: string,
        setFieldError: (errorMessage: string) => void,
        resetForm: (nextState?: unknown) => void
    ) => {
        let response: {
            options: {
                publicKey: PublicKeyCredentialCreationOptions;
            };
            sessionID: string;
        };

        try {
            response = await getPasskeyRegistrationOptions();
        } catch {
            setFieldError('Failed to begin registration');
            return;
        }

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
        let newCredential: Credential | null = null;

        try {
            newCredential = await navigator.credentials.create(options);
        } catch (e) {
            logError(e, 'Error creating credential');
            setFieldError('Failed to create credential');
            return;
        }

        try {
            await finishPasskeyRegistration(
                inputValue,
                newCredential,
                response.sessionID
            );
        } catch {
            setFieldError('Failed to finish registration');
            return;
        }

        await init();
        resetForm();
    };

    return (
        <>
            <PasskeysContext.Provider
                value={{
                    selectedPasskey,
                    setSelectedPasskey,
                    setShowPasskeyDrawer,
                    refreshPasskeys: init,
                }}>
                <CenteredFlex>
                    <Box maxWidth="20rem">
                        <Box marginBottom="1rem">
                            <Typography>{t('PASSKEYS_DESCRIPTION')}</Typography>
                        </Box>
                        <FormPaper
                            style={{
                                padding: '1rem',
                            }}>
                            <SingleInputForm
                                fieldType="text"
                                placeholder={t('ENTER_PASSKEY_NAME')}
                                buttonText={t('ADD_PASSKEY')}
                                initialValue={''}
                                callback={handleSubmit}
                                submitButtonProps={{
                                    sx: {
                                        marginBottom: 1,
                                    },
                                }}
                            />
                        </FormPaper>
                        <Box marginTop="1rem">
                            <PasskeysList passkeys={passkeys} />
                        </Box>
                    </Box>
                </CenteredFlex>
                <ManagePasskeyDrawer open={showPasskeyDrawer} />
            </PasskeysContext.Provider>
        </>
    );
};

export default Passkeys;
