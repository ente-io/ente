import { setClientPackageForAuthenticatedRequests } from "@/next/http";
import log from "@/next/log";
import { clientPackageName } from "@/next/types/app";
import { nullToUndefined } from "@/utils/transform";
import {
    CenteredFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteButton from "@ente/shared/components/EnteButton";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { fromB64URLSafeNoPadding } from "@ente/shared/crypto/internal/libsodium";
import HTTPService from "@ente/shared/network/HTTPService";
import InfoIcon from "@mui/icons-material/Info";
import { Box, Paper, Typography, styled } from "@mui/material";
import { t } from "i18next";
import _sodium from "libsodium-wrappers";
import { useEffect, useState } from "react";
import {
    beginPasskeyAuthentication,
    finishPasskeyAuthentication,
    isWhitelistedRedirect,
    type BeginPasskeyAuthenticationResponse,
} from "services/passkey";

const Page = () => {
    /**
     * The state of our component as we go through the passkey authentication
     * flow.
     *
     * To avoid confusion with useState, we call it status instead. */
    type Status =
        | "loading" /* Can happen multiple times in the flow */
        | "unknownRedirect" /* Unrecoverable error */
        | "failed" /* Generic error */
        | "waitingForUser"; /* ...to authenticate with their passkey */

    const [status, setStatus] = useState<Status>("loading");

    /** (re)start the authentication flow */
    const authenticate = async () => {
        const searchParams = new URLSearchParams(window.location.search);

        // Extract redirect from the query params.
        const redirect = nullToUndefined(searchParams.get("redirect"));
        const redirectURL = redirect ? new URL(redirect) : undefined;

        // Ensure that redirectURL is whitelisted, otherwise show an invalid
        // "login" URL error to the user.
        if (!redirectURL || !isWhitelistedRedirect(redirectURL)) {
            log.error(`Redirect URL '${redirectURL}' is not whitelisted`);
            setStatus("unknownRedirect");
            return;
        }

        let clientPackage = nullToUndefined(searchParams.get("client"));
        // Mobile apps don't pass the client header, deduce their client package
        // name from the redirect URL that they provide. TODO-PK: Pass?
        if (!clientPackage) {
            clientPackage = clientPackageName["photos"];
            if (redirectURL.protocol === "enteauth:") {
                clientPackage = clientPackageName["auth"];
            } else if (redirectURL.hostname.startsWith("accounts")) {
                clientPackage = clientPackageName["accounts"];
            }
        }

        localStorage.setItem("clientPackage", clientPackage);
        // The server needs to know the app on whose behalf we're trying to
        // authenticate.
        setClientPackageForAuthenticatedRequests(clientPackage);
        HTTPService.setHeaders({
            "X-Client-Package": clientPackage,
        });

        // get passkeySessionID from the query params
        const passkeySessionID = searchParams.get("passkeySessionID") as string;

        setStatus("loading");

        let beginData: BeginPasskeyAuthenticationResponse;

        try {
            beginData = await beginAuthentication(passkeySessionID);
            setStatus("waitingForUser");
        } catch (e) {
            log.error("Couldn't begin passkey authentication", e);
            setStatus("failed");
            return;
        }

        let credential: Credential | null = null;

        let tries = 0;
        const maxTries = 3;

        while (tries < maxTries) {
            try {
                credential = await getCredential(beginData.options.publicKey);
            } catch (e) {
                log.error("Couldn't get credential", e);
                continue;
            } finally {
                tries++;
            }

            break;
        }

        if (!credential) {
            if (!isWebAuthnSupported()) {
                alert("WebAuthn is not supported in this browser");
            }
            setStatus("failed");
            return;
        }

        setStatus("loading");

        let finishData;

        try {
            finishData = await finishAuthentication(
                credential,
                passkeySessionID,
                beginData.ceremonySessionID,
            );
        } catch (e) {
            log.error("Couldn't finish passkey authentication", e);
            setStatus("failed");
            return;
        }

        // Conceptually we can `setStatus("done")` at this point, but we'll
        // leave this page anyway, so no need to tickle React.

        const encodedResponse = _sodium.to_base64(JSON.stringify(finishData));

        // TODO-PK: Shouldn't this be URL encoded?
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
        timeoutMillis: number = 60000, // Default timeout of 60 seconds
    ): Promise<Credential | null> => {
        publicKey.challenge = await fromB64URLSafeNoPadding(
            publicKey.challenge,
        );
        for (const listItem of publicKey.allowCredentials ?? []) {
            listItem.id = await fromB64URLSafeNoPadding(listItem.id);
            // note: we are orverwriting the transports array with all possible values.
            // This is because the browser will only prompt the user for the transport that is available.
            // Warning: In case of invalid transport value, the webauthn will fail on Safari & iOS browsers
            listItem.transports = ["usb", "nfc", "ble", "internal"];
        }
        publicKey.timeout = timeoutMillis;
        const publicKeyCredentialCreationOptions: CredentialRequestOptions = {
            publicKey: publicKey,
        };
        const credential = await navigator.credentials.get(
            publicKeyCredentialCreationOptions,
        );
        return credential;
    };

    const finishAuthentication = async (
        credential: Credential,
        sessionId: string,
        ceremonySessionId: string,
    ) => {
        const data = await finishPasskeyAuthentication(
            credential,
            sessionId,
            ceremonySessionId,
        );
        return data;
    };

    useEffect(() => {
        void authenticate();
    }, []);

    const components: Record<Status, React.ReactNode> = {
        loading: <Loading />,
        unknownRedirect: <UnknownRedirect />,
        failed: <Failed onRetry={() => void authenticate()} />,
        waitingForUser: <WaitingForUser />,
    };

    return components[status];
};

export default Page;

const Loading: React.FC = () => {
    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

const UnknownRedirect: React.FC = () => {
    return (
        <UnknownRedirect_>
            <UnknownRedirectPaper>
                <InfoIcon />
                <Typography variant="h3">
                    {t("PASSKEY_LOGIN_FAILED")}
                </Typography>
                <Typography marginTop="1rem">
                    {t("PASSKEY_LOGIN_URL_INVALID")}
                </Typography>
            </UnknownRedirectPaper>
        </UnknownRedirect_>
    );
};

const UnknownRedirect_ = styled("div")`
    display: flex;
    height: 100%;
    justify-content: center;
    align-items: center;
`;

const UnknownRedirectPaper = styled(Paper)`
    width: 100%;
    max-width: 24rem;
    padding: 1rem;
`;

interface FailedProps {
    /** Callback invoked when the user presses the try again button. */
    onRetry: () => void;
}

const Failed: React.FC<FailedProps> = ({ onRetry }) => {
    return (
        <Box
            display="flex"
            justifyContent="center"
            alignItems="center"
            height="100%"
        >
            <Box maxWidth="30rem">
                <FormPaper
                    style={{
                        padding: "1rem",
                    }}
                >
                    <InfoIcon />
                    <Typography fontWeight="bold" variant="h1">
                        {t("PASSKEY_LOGIN_FAILED")}
                    </Typography>
                    <Typography marginTop="1rem">
                        {t("PASSKEY_LOGIN_ERRORED")}
                    </Typography>
                    <EnteButton
                        onClick={onRetry}
                        fullWidth
                        style={{
                            marginTop: "1rem",
                        }}
                        color="primary"
                        type="button"
                        variant="contained"
                    >
                        {t("TRY_AGAIN")}
                    </EnteButton>
                    <EnteButton
                        href="/passkeys/recover"
                        fullWidth
                        style={{
                            marginTop: "1rem",
                        }}
                        color="primary"
                        type="button"
                        variant="text"
                    >
                        {t("RECOVER_TWO_FACTOR")}
                    </EnteButton>
                </FormPaper>
            </Box>
        </Box>
    );
};

const WaitingForUser: React.FC = () => {
    return (
        <>
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                height="100%"
            >
                <Box maxWidth="30rem">
                    <FormPaper
                        style={{
                            padding: "1rem",
                        }}
                    >
                        <InfoIcon />
                        <Typography fontWeight="bold" variant="h1">
                            {t("LOGIN_WITH_PASSKEY")}
                        </Typography>
                        <Typography marginTop="1rem">
                            {t("PASSKEY_FOLLOW_THE_STEPS_FROM_YOUR_BROWSER")}
                        </Typography>
                        <CenteredFlex marginTop="1rem">
                            <img
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
