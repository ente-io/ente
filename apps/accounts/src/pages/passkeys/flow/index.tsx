import { CenteredFlex } from '@ente/shared/components/Container';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import { Box, Typography } from '@mui/material';
import InfoIcon from '@mui/icons-material/Info';
import Image from 'next/image';
import { useEffect } from 'react';
import {
    BeginPasskeyAuthenticationResponse,
    beginPasskeyAuthentication,
    finishPasskeyAuthentication,
} from 'services/passkeysService';
import { logError } from '@ente/shared/sentry';
import _sodium from 'libsodium-wrappers';

const PasskeysFlow = () => {
    const init = async () => {
        // get passkeySessionID from the query params
        const searchParams = new URLSearchParams(window.location.search);
        const passkeySessionID = searchParams.get('passkeySessionID');

        let beginData: BeginPasskeyAuthenticationResponse;

        try {
            beginData = await beginAuthentication(passkeySessionID);
        } catch (e) {
            logError(e, "Couldn't begin passkey authentication");
            return;
        }

        let credential: Credential;

        try {
            credential = await getCredential(beginData.options.publicKey);
        } catch (e) {
            logError(e, "Couldn't get credential");
            return;
        }

        let finishData;

        try {
            finishData = await finishAuthentication(
                credential,
                passkeySessionID,
                beginData.ceremonySessionID
            );
        } catch (e) {
            logError(e, "Couldn't finish passkey authentication");
            return;
        }

        const encodedResponse = _sodium.to_base64(JSON.stringify(finishData));

        // get redirect from the query params
        const redirect = searchParams.get('redirect');

        window.location.href = `${redirect}?response=${encodedResponse}`;
    };

    const beginAuthentication = async (sessionId: string) => {
        const data = await beginPasskeyAuthentication(sessionId);
        return data;
    };

    const getCredential = async (publicKey: any): Promise<Credential> => {
        publicKey.challenge = _sodium.from_base64(
            publicKey.challenge,
            _sodium.base64_variants.URLSAFE_NO_PADDING
        );
        publicKey.allowCredentials?.forEach(function (listItem) {
            listItem.id = _sodium.from_base64(
                listItem.id,
                _sodium.base64_variants.URLSAFE_NO_PADDING
            );
        });

        const credential = await navigator.credentials.get({
            publicKey,
        });

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
                        <Typography fontWeight="bold" variant="h4">
                            Login with Passkey
                        </Typography>
                        <Typography marginTop="1rem">
                            Follow the steps from your browser to continue
                            logging into Ente
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
