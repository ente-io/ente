import { APPS, CLIENT_PACKAGE_NAMES } from '@ente/shared/apps/constants';
import {
    CenteredFlex,
    VerticallyCentered,
} from '@ente/shared/components/Container';
import EnteButton from '@ente/shared/components/EnteButton';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import HTTPService from '@ente/shared/network/HTTPService';
import { logError } from '@ente/shared/sentry';
import { LS_KEYS, setData } from '@ente/shared/storage/localStorage';
import InfoIcon from '@mui/icons-material/Info';
import { Box, Typography } from '@mui/material';
import { t } from 'i18next';
import _sodium from 'libsodium-wrappers';
import Image from 'next/image';
import { useEffect, useState } from 'react';
import {
    BeginPasskeyAuthenticationResponse,
    beginPasskeyAuthentication,
    finishPasskeyAuthentication,
} from 'services/passkeysService';

const PasskeysFlow = () => {
    const [errored, setErrored] = useState(false);

    const [invalidInfo, setInvalidInfo] = useState(false);

    const [loading, setLoading] = useState(true);

    const init = async () => {
        const searchParams = new URLSearchParams(window.location.search);

        // get redirect from the query params
        const redirect = searchParams.get('redirect') as string;

        const redirectURL = new URL(redirect);
        if (process.env.NEXT_PUBLIC_DISABLE_REDIRECT_CHECK !== 'true') {
            if (
                redirect !== '' &&
                !(
                    redirectURL.host.endsWith('.ente.io') ||
                    redirectURL.host.endsWith('bada-frame.pages.dev')
                ) &&
                redirectURL.protocol !== 'ente:' &&
                redirectURL.protocol !== 'enteauth:'
            ) {
                setInvalidInfo(true);
                setLoading(false);
                return;
            }
        }

        let pkg = CLIENT_PACKAGE_NAMES.get(APPS.PHOTOS);
        if (redirectURL.protocol === 'enteauth:') {
            pkg = CLIENT_PACKAGE_NAMES.get(APPS.AUTH);
        } else if (redirectURL.hostname.startsWith('accounts')) {
            pkg = CLIENT_PACKAGE_NAMES.get(APPS.ACCOUNTS);
        }

        setData(LS_KEYS.CLIENT_PACKAGE, { name: pkg });
        HTTPService.setHeaders({
            'X-Client-Package': pkg,
        });

        // get passkeySessionID from the query params
        const passkeySessionID = searchParams.get('passkeySessionID') as string;

        setLoading(true);

        let beginData: BeginPasskeyAuthenticationResponse;

        try {
            beginData = await beginAuthentication(passkeySessionID);
        } catch (e) {
            logError(e, "Couldn't begin passkey authentication");
            setErrored(true);
            return;
        } finally {
            setLoading(false);
        }

        let credential: Credential | null = null;

        let tries = 0;
        const maxTries = 3;

        while (tries < maxTries) {
            try {
                credential = await getCredential(beginData.options.publicKey);
            } catch (e) {
                logError(e, "Couldn't get credential");
                continue;
            } finally {
                tries++;
            }

            break;
        }

        if (!credential) {
            if (!isWebAuthnSupported()) {
                alert('WebAuthn is not supported in this browser');
            }
            setErrored(true);
            return;
        }

        setLoading(true);

        let finishData;

        try {
            finishData = await finishAuthentication(
                credential,
                passkeySessionID,
                beginData.ceremonySessionID
            );
        } catch (e) {
            logError(e, "Couldn't finish passkey authentication");
            setErrored(true);
            setLoading(false);
            return;
        }

        const encodedResponse = _sodium.to_base64(JSON.stringify(finishData));

        window.location.href = `${redirect}?response=${encodedResponse}`;
    };

    const beginAuthentication = async (sessionId: string) => {
        const data = await beginPasskeyAuthentication(sessionId);
        return data;
    };

    function isWebAuthnSupported(): boolean {
        if (!navigator.credentials) {
            return false;
        }
        return true;
    }

    const getCredential = async (
        publicKey: any,
        timeoutMillis: number = 60000 // Default timeout of 60 seconds
    ): Promise<Credential | null> => {
        publicKey.challenge = _sodium.from_base64(
            publicKey.challenge,
            _sodium.base64_variants.URLSAFE_NO_PADDING
        );
        publicKey.allowCredentials?.forEach(function (listItem: any) {
            listItem.id = _sodium.from_base64(
                listItem.id,
                _sodium.base64_variants.URLSAFE_NO_PADDING
            );
            // note: we are orverwriting the transports array with all possible values.
            // This is because the browser will only prompt the user for the transport that is available.
            // Warning: In case of invalid transport value, the webauthn will fail on Safari & iOS browsers
            listItem.transports = ['usb', 'nfc', 'ble', 'internal'];
        });
        publicKey.timeout = timeoutMillis;
        const publicKeyCredentialCreationOptions: CredentialRequestOptions = {
            publicKey: publicKey,
        };
        const credential = await navigator.credentials.get(
            publicKeyCredentialCreationOptions
        );
        return credential;
    };

    const finishAuthentication = async (
        credential: Credential,
        sessionId: string,
        ceremonySessionId: string
    ) => {
        const data = await finishPasskeyAuthentication(
            credential,
            sessionId,
            ceremonySessionId
        );
        return data;
    };

    useEffect(() => {
        init();
    }, []);

    if (loading) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    if (invalidInfo) {
        return (
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                height="100%">
                <Box maxWidth="30rem">
                    <FormPaper
                        style={{
                            padding: '1rem',
                        }}>
                        <InfoIcon />
                        <Typography fontWeight="bold" variant="h1">
                            {t('PASSKEY_LOGIN_FAILED')}
                        </Typography>
                        <Typography marginTop="1rem">
                            {t('PASSKEY_LOGIN_URL_INVALID')}
                        </Typography>
                    </FormPaper>
                </Box>
            </Box>
        );
    }

    if (errored) {
        return (
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                height="100%">
                <Box maxWidth="30rem">
                    <FormPaper
                        style={{
                            padding: '1rem',
                        }}>
                        <InfoIcon />
                        <Typography fontWeight="bold" variant="h1">
                            {t('PASSKEY_LOGIN_FAILED')}
                        </Typography>
                        <Typography marginTop="1rem">
                            {t('PASSKEY_LOGIN_ERRORED')}
                        </Typography>
                        <EnteButton
                            onClick={() => {
                                setErrored(false);
                                init();
                            }}
                            fullWidth
                            style={{
                                marginTop: '1rem',
                            }}
                            color="primary"
                            type="button"
                            variant="contained">
                            {t('TRY_AGAIN')}
                        </EnteButton>
                    </FormPaper>
                </Box>
            </Box>
        );
    }

    return (
        <>
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                height="100%">
                <Box maxWidth="30rem">
                    <FormPaper
                        style={{
                            padding: '1rem',
                        }}>
                        <InfoIcon />
                        <Typography fontWeight="bold" variant="h1">
                            {t('LOGIN_WITH_PASSKEY')}
                        </Typography>
                        <Typography marginTop="1rem">
                            {t('PASSKEY_FOLLOW_THE_STEPS_FROM_YOUR_BROWSER')}
                        </Typography>
                        <CenteredFlex marginTop="1rem">
                            <Image
                                alt="ente Logo Circular"
                                height={150}
                                width={150}
                                src="/images/ente-circular.png"
                            />
                        </CenteredFlex>
                    </FormPaper>
                </Box>
            </Box>
        </>
    );
};

export default PasskeysFlow;
