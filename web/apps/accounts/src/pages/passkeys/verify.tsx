import { TwoFactorAuthorizationResponse } from "@/accounts/services/user";
import { Stack100vhCenter } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import log from "@/base/log";
import { nullToUndefined } from "@/utils/transform";
import InfoIcon from "@mui/icons-material/Info";
import KeyIcon from "@mui/icons-material/Key";
import { Paper, Typography, styled } from "@mui/material";
import { t } from "i18next";
import React, { useCallback, useEffect, useState } from "react";
import {
    beginPasskeyAuthentication,
    finishPasskeyAuthentication,
    isWebAuthnSupported,
    isWhitelistedRedirect,
    passkeyAuthenticationSuccessRedirectURL,
    passkeySessionAlreadyClaimedErrorMessage,
    redirectToPasskeyRecoverPage,
    signChallenge,
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
        | "webAuthnNotSupported" /* Unrecoverable error */
        | "unknownRedirect" /* Unrecoverable error */
        | "sessionAlreadyClaimed" /* Unrecoverable error */
        | "unrecoverableFailure" /* Unrecoverable error - generic */
        | "failedDuringSignChallenge" /* Recoverable error in signChallenge */
        | "failed" /* Recoverable error otherwise */
        | "needUserFocus" /* See docs for `Continuation` */
        | "waitingForUser" /* ...to authenticate with their passkey */
        | "redirectingWeb" /* Redirect back to the requesting app (HTTP) */
        | "redirectingApp"; /* Other redirects (mobile / desktop redirect) */

    const [status, setStatus] = useState<Status>("loading");

    /**
     * Safari keeps on saying "NotAllowedError: The document is not focused"
     * even though it just opened the page and brought it to the front.
     *
     * Because of their incompetence, we need to break our entire flow into two
     * parts, and stash away a lot of state when we're in the "needUserFocus"
     * state.
     */
    interface Continuation {
        redirectURL: URL;
        clientPackage: string;
        passkeySessionID: string;
        beginResponse: BeginPasskeyAuthenticationResponse;
    }
    const [continuation, setContinuation] = useState<
        Continuation | undefined
    >();

    // Safari throws  sometimes
    // (no reason, just to show their incompetence). The retry doesn't seem to
    // help mostly, but cargo cult anyway.

    // The URL we're redirecting to on success.
    //
    // This will only be set when status is "redirecting*".
    const [successRedirectURL, setSuccessRedirectURL] = useState<
        URL | undefined
    >();

    /** Phase 1 of {@link authenticate}. */
    const authenticateBegin = useCallback(async () => {
        if (!isWebAuthnSupported()) {
            setStatus("webAuthnNotSupported");
            return;
        }

        const searchParams = new URLSearchParams(window.location.search);

        // Extract redirect from the query params.
        const redirect = nullToUndefined(searchParams.get("redirect"));
        const redirectURL = redirect ? new URL(redirect) : undefined;

        // Ensure that redirectURL is whitelisted, otherwise show an invalid
        // "login" URL error to the user.
        if (!redirectURL || !isWhitelistedRedirect(redirectURL)) {
            log.error(`Redirect '${redirect}' is not whitelisted`);
            setStatus("unknownRedirect");
            return;
        }

        // The server needs to know the app on whose behalf we're trying to
        // authenticate.
        const clientPackage = nullToUndefined(
            searchParams.get("clientPackage"),
        );
        if (!clientPackage) {
            setStatus("unrecoverableFailure");
            return;
        }

        setStatus("loading");

        // Extract passkeySessionID from the query params.
        const passkeySessionID = nullToUndefined(
            searchParams.get("passkeySessionID"),
        );
        if (!passkeySessionID) {
            setStatus("unrecoverableFailure");
            return;
        }

        let beginResponse: BeginPasskeyAuthenticationResponse;
        try {
            beginResponse = await beginPasskeyAuthentication(passkeySessionID);
        } catch (e) {
            log.error("Failed to begin passkey authentication", e);
            setStatus(
                e instanceof Error &&
                    e.message == passkeySessionAlreadyClaimedErrorMessage
                    ? "sessionAlreadyClaimed"
                    : "failed",
            );
            return;
        }

        return {
            redirectURL,
            passkeySessionID,
            clientPackage,
            beginResponse,
        };
    }, []);

    /**
     * Phase 2 of {@link authenticate}, separated by a potential user
     * interaction.
     */
    const authenticateContinue = useCallback(async (cont: Continuation) => {
        const { redirectURL, passkeySessionID, clientPackage, beginResponse } =
            cont;
        const { ceremonySessionID, options } = beginResponse;

        setStatus("waitingForUser");

        let credential: Credential | undefined;
        try {
            credential = await signChallenge(options.publicKey);
            if (!credential) {
                setStatus("failedDuringSignChallenge");
                return;
            }
        } catch (e) {
            log.error("Failed to get credentials", e);
            if (
                e instanceof Error &&
                e.name == "NotAllowedError" &&
                e.message == "The document is not focused."
            ) {
                setStatus("needUserFocus");
            } else {
                setStatus("failedDuringSignChallenge");
            }
            return;
        }

        setStatus("loading");

        let authorizationResponse: TwoFactorAuthorizationResponse;
        try {
            authorizationResponse = await finishPasskeyAuthentication({
                passkeySessionID,
                ceremonySessionID,
                clientPackage,
                credential,
            });
        } catch (e) {
            log.error("Failed to finish passkey authentication", e);
            setStatus("failed");
            return;
        }

        setStatus(isHTTP(redirectURL) ? "redirectingWeb" : "redirectingApp");

        setSuccessRedirectURL(
            await passkeyAuthenticationSuccessRedirectURL(
                redirectURL,
                passkeySessionID,
                authorizationResponse,
            ),
        );
    }, []);

    /** (re)start the authentication flow */
    const authenticate = useCallback(async () => {
        const cont = await authenticateBegin();
        if (cont) {
            setContinuation(cont);
            await authenticateContinue(cont);
        }
    }, [authenticateBegin, authenticateContinue]);

    useEffect(() => {
        void authenticate();
    }, [authenticate]);

    useEffect(() => {
        if (successRedirectURL) redirectToURL(successRedirectURL);
    }, [successRedirectURL]);

    const handleVerify = () => void authenticateContinue(continuation!);

    const handleRetry = () => void authenticate();

    const handleRecover = (() => {
        const searchParams = new URLSearchParams(window.location.search);
        const recover = nullToUndefined(searchParams.get("recover"));
        if (!recover) {
            // [Note: Conditional passkey recover option on accounts]
            //
            // Only show the recover option if the calling app provided us with
            // the "recover" query parameter. For example, the mobile app does
            // not pass it since it already shows a recovery option within the
            // waiting screen that it shows.
            return undefined;
        }

        return () => redirectToPasskeyRecoverPage(new URL(recover));
    })();

    const handleRedirectAgain = () => redirectToURL(successRedirectURL!);

    const components: Record<Status, React.ReactNode> = {
        loading: <ActivityIndicator />,
        unknownRedirect: <UnknownRedirect />,
        webAuthnNotSupported: <WebAuthnNotSupported />,
        sessionAlreadyClaimed: <SessionAlreadyClaimed />,
        unrecoverableFailure: <UnrecoverableFailure />,
        failedDuringSignChallenge: (
            <RetriableFailed
                duringSignChallenge
                onRetry={handleRetry}
                onRecover={handleRecover}
            />
        ),
        failed: (
            <RetriableFailed onRetry={handleRetry} onRecover={handleRecover} />
        ),
        needUserFocus: <Verify onVerify={handleVerify} />,
        waitingForUser: <WaitingForUser />,
        redirectingWeb: <RedirectingWeb />,
        redirectingApp: <RedirectingApp onRetry={handleRedirectAgain} />,
    };

    return <Stack100vhCenter>{components[status]}</Stack100vhCenter>;
};

export default Page;

// Not 100% accurate, but good enough for our purposes.
const isHTTP = (url: URL) => url.protocol.startsWith("http");

const redirectToURL = (url: URL) => {
    log.info(`Redirecting to ${url.href}`);
    window.location.href = url.href;
};

const UnknownRedirect: React.FC = () => (
    <Failed message={t("passkey_login_invalid_url")} />
);

const WebAuthnNotSupported: React.FC = () => (
    <Failed message={t("passkeys_not_supported")} />
);

const SessionAlreadyClaimed: React.FC = () => (
    <ContentPaper>
        <SessionAlreadyClaimed_>
            <InfoIcon color="secondary" />
            <Typography>
                {t("passkey_login_already_claimed_session")}
            </Typography>
        </SessionAlreadyClaimed_>
    </ContentPaper>
);

const SessionAlreadyClaimed_ = styled("div")`
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2rem;
`;

const UnrecoverableFailure: React.FC = () => (
    <Failed message={t("passkey_login_generic_error")} />
);

interface FailedProps {
    message: string;
}

const Failed: React.FC<FailedProps> = ({ message }) => (
    <ContentPaper>
        <InfoIcon color="secondary" />
        <Typography variant="h6">{t("passkey_login_failed")}</Typography>
        <Typography sx={{ color: "text.muted" }}>{message}</Typography>
    </ContentPaper>
);

const ContentPaper = styled(Paper)`
    width: 100%;
    max-width: 24rem;
    padding: 1rem;
    /* Slight asymmetry, look visually better since the bottom half of the paper
       is usually muted text that carries less visual weight. */
    padding-block-end: 1.15rem;

    display: flex;
    flex-direction: column;
    gap: 1rem;
`;

interface VerifyProps {
    /** Called when the user presses the "Verify" button. */
    onVerify: () => void;
}

/**
 * Gain focus for the current page by requesting the user to explicitly click a
 * button. For more details, see the documentation for `Continuation`.
 */
const Verify: React.FC<VerifyProps> = ({ onVerify }) => (
    <ContentPaper>
        <KeyIcon color="secondary" fontSize="large" />
        <Typography variant="h3">{t("passkey")}</Typography>
        <Typography sx={{ color: "text.muted" }}>
            {t("passkey_verify_description")}
        </Typography>
        <ButtonStack>
            <FocusVisibleButton onClick={onVerify} fullWidth color="accent">
                {t("verify")}
            </FocusVisibleButton>
        </ButtonStack>
    </ContentPaper>
);

interface RetriableFailedProps {
    /**
     * Set this attribute to indicate that this failure occurred during the
     * actual passkey verification (`navigator.credentials.get`).
     *
     * We customize the error message for such cases to give a hint to the user
     * that they can try on their other devices too.
     */
    duringSignChallenge?: boolean;
    /** Callback invoked when the user presses the try again button. */
    onRetry: () => void;
    /**
     * Callback invoked when the user presses the button to recover their second
     * factor, e.g. if they cannot login using it.
     *
     * This is optional. See [Note: Conditional passkey recover option on
     * accounts].
     */
    onRecover: (() => void) | undefined;
}

const RetriableFailed: React.FC<RetriableFailedProps> = ({
    duringSignChallenge,
    onRetry,
    onRecover,
}) => (
    <ContentPaper>
        <InfoIcon color="secondary" fontSize="large" />
        <Typography variant="h5">{t("passkey_login_failed")}</Typography>
        <Typography sx={{ color: "text.muted" }}>
            {duringSignChallenge
                ? t("passkey_login_credential_hint")
                : t("passkey_login_generic_error")}
        </Typography>
        <ButtonStack>
            <FocusVisibleButton onClick={onRetry} fullWidth color="secondary">
                {t("try_again")}
            </FocusVisibleButton>
            {onRecover && (
                <FocusVisibleButton
                    onClick={onRecover}
                    fullWidth
                    variant="text"
                >
                    {t("recover_two_factor")}
                </FocusVisibleButton>
            )}
        </ButtonStack>
    </ContentPaper>
);

const ButtonStack = styled("div")`
    display: flex;
    flex-direction: column;
    margin-block-start: 1rem;
    gap: 1rem;
`;

const WaitingForUser: React.FC = () => (
    <ContentPaper>
        <Typography variant="h3" sx={{ mt: 1 }}>
            {t("passkey_login")}
        </Typography>
        <Typography sx={{ color: "text.muted" }}>
            {t("passkey_login_instructions")}
        </Typography>
        <WaitingImgContainer>
            <img
                alt=""
                height={150}
                width={150}
                src="/images/ente-circular.png"
            />
        </WaitingImgContainer>
    </ContentPaper>
);

const WaitingImgContainer = styled("div")`
    display: flex;
    justify-content: center;
    margin-block-start: 1rem;
`;

const RedirectingWeb: React.FC = () => (
    <ContentPaper>
        <InfoIcon color="accent" fontSize="large" />
        <Typography variant="h5">{t("passkey_verified")}</Typography>
        <Typography sx={{ color: "text.muted" }}>
            {t("redirecting_back_to_app")}
        </Typography>
    </ContentPaper>
);

interface RedirectingAppProps {
    /** Called when the user presses the button to redirect again */
    onRetry: () => void;
}

const RedirectingApp: React.FC<RedirectingAppProps> = ({ onRetry }) => (
    <ContentPaper>
        <InfoIcon color="accent" fontSize="large" />
        <Typography variant="h5">{t("passkey_verified")}</Typography>
        <Typography sx={{ color: "text.muted" }}>
            {t("redirecting_back_to_app")}
        </Typography>
        <Typography sx={{ color: "text.muted" }}>
            {t("redirect_close_instructions")}
        </Typography>
        <ButtonStack>
            <FocusVisibleButton fullWidth color="secondary" onClick={onRetry}>
                {t("redirect_again")}
            </FocusVisibleButton>
        </ButtonStack>
    </ContentPaper>
);
