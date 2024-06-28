import log from "@/next/log";
import { customAPIHost } from "@/next/origins";
import type { BaseAppContextT } from "@/next/types/app";
import {
    checkPasskeyVerificationStatus,
    passkeySessionExpiredErrorMessage,
    saveCredentialsAndNavigateTo,
} from "@ente/accounts/services/passkey";
import EnteButton from "@ente/shared/components/EnteButton";
import { CircularProgress, Stack, Typography, styled } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { VerticallyCentered } from "./Container";
import type { DialogBoxAttributesV2 } from "./DialogBoxV2/types";
import { genericErrorAttributes } from "./ErrorComponents";
import FormPaper from "./Form/FormPaper";
import FormPaperFooter from "./Form/FormPaper/Footer";
import LinkButton from "./LinkButton";

export const PasswordHeader: React.FC<React.PropsWithChildren> = ({
    children,
}) => {
    return (
        <Header_>
            <Typography variant="h2">{t("password")}</Typography>
            <Typography color="text.faint">{children}</Typography>
        </Header_>
    );
};

const PasskeyHeader: React.FC<React.PropsWithChildren> = ({ children }) => {
    return (
        <Header_>
            <Typography variant="h3">{"Passkey"}</Typography>
            <Typography color="text.faint">{children}</Typography>
        </Header_>
    );
};

const Header_ = styled("div")`
    margin-block-end: 4rem;
    display: flex;
    flex-direction: column;
    gap: 8px;
`;

export const LoginFlowFormFooter: React.FC<React.PropsWithChildren> = ({
    children,
}) => {
    const [host, setHost] = useState<string | undefined>();

    useEffect(() => void customAPIHost().then(setHost), []);

    return (
        <FormPaperFooter>
            <Stack gap="16px" width="100%" textAlign="start">
                {children}

                {host && (
                    <Typography variant="small" color="text.faint">
                        {host}
                    </Typography>
                )}
            </Stack>
        </FormPaperFooter>
    );
};

interface VerifyingPasskeyProps {
    /** ID of the current passkey verification session. */
    passkeySessionID: string;
    /** The email of the user whose passkey we're verifying. */
    email: string | undefined;
    /** Called when the user wants to redirect again. */
    onRetry: () => void;
    /**
     * The appContext.
     *
     * Needs to be explicitly passed since this component is used in a package
     * where the pages are not wrapped in the provider.
     */
    appContext: BaseAppContextT;
}

export const VerifyingPasskey: React.FC<VerifyingPasskeyProps> = ({
    passkeySessionID,
    email,
    onRetry,
    appContext,
}) => {
    const { logout, setDialogBoxAttributesV2 } = appContext;

    type VerificationStatus = "waiting" | "checking" | "pending";
    const [verificationStatus, setVerificationStatus] =
        useState<VerificationStatus>("waiting");

    const router = useRouter();

    const handleRetry = () => {
        setVerificationStatus("waiting");
        onRetry();
    };

    const handleCheckStatus = async () => {
        setVerificationStatus("checking");
        try {
            const response =
                await checkPasskeyVerificationStatus(passkeySessionID);
            if (!response) setVerificationStatus("pending");
            else router.push(saveCredentialsAndNavigateTo(response));
        } catch (e) {
            log.error("Passkey verification status check failed", e);
            setDialogBoxAttributesV2(
                e instanceof Error &&
                    e.message == passkeySessionExpiredErrorMessage
                    ? sessionExpiredDialogAttributes(logout)
                    : genericErrorAttributes(),
            );
            setVerificationStatus("waiting");
        }
    };

    const handleRecover = () => {
        router.push("/passkeys/recover");
    };

    return (
        <VerticallyCentered>
            <FormPaper style={{ minWidth: "320px" }}>
                <PasskeyHeader>{email ?? ""}</PasskeyHeader>

                <VerifyingPasskeyMiddle>
                    <VerifyingPasskeyStatus>
                        {verificationStatus == "checking" ? (
                            <Typography>
                                <CircularProgress color="accent" size="1.5em" />
                            </Typography>
                        ) : (
                            <Typography color="text.muted">
                                {verificationStatus == "waiting"
                                    ? t("waiting_for_verification")
                                    : t("verification_still_pending")}
                            </Typography>
                        )}
                    </VerifyingPasskeyStatus>

                    <ButtonStack>
                        <EnteButton
                            onClick={handleRetry}
                            fullWidth
                            color="secondary"
                            type="button"
                        >
                            {t("try_again")}
                        </EnteButton>

                        <EnteButton
                            onClick={handleCheckStatus}
                            fullWidth
                            color="accent"
                            type="button"
                        >
                            {t("check_status")}
                        </EnteButton>
                    </ButtonStack>
                </VerifyingPasskeyMiddle>

                <LoginFlowFormFooter>
                    <Stack direction="row" justifyContent="space-between">
                        <LinkButton onClick={handleRecover}>
                            {t("RECOVER_ACCOUNT")}
                        </LinkButton>
                        <LinkButton onClick={logout}>
                            {t("CHANGE_EMAIL")}
                        </LinkButton>
                    </Stack>
                </LoginFlowFormFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

const VerifyingPasskeyMiddle = styled("div")`
    display: flex;
    flex-direction: column;

    padding-block: 1rem;
    gap: 4rem;
`;

const VerifyingPasskeyStatus = styled("div")`
    text-align: center;
    /* Size of the CircularProgress (+ some margin) so that there is no layout
       shift when it is shown */
    min-height: 2em;
`;

const ButtonStack = styled("div")`
    display: flex;
    flex-direction: column;
    gap: 1rem;
`;

/**
 * {@link DialogBoxAttributesV2} for showing the error when the user's session
 * has expired.
 *
 * It asks them to login again. There is one button, which allows them to
 * logout.
 *
 * @param onLogin Called when the user presses the "Login" button on the error
 * dialog.
 */
export const sessionExpiredDialogAttributes = (
    onLogin: () => void,
): DialogBoxAttributesV2 => ({
    title: t("SESSION_EXPIRED"),
    content: t("SESSION_EXPIRED_MESSAGE"),
    nonClosable: true,
    proceed: {
        text: t("LOGIN"),
        action: onLogin,
        variant: "accent",
    },
});
