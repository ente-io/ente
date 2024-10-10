import {
    checkPasskeyVerificationStatus,
    passkeySessionExpiredErrorMessage,
    saveCredentialsAndNavigateTo,
} from "@/accounts/services/passkey";
import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { genericErrorDialogAttributes } from "@/base/components/utils/mini-dialog";
import log from "@/base/log";
import { customAPIHost } from "@/base/origins";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import LinkButton from "@ente/shared/components/LinkButton";
import { CircularProgress, Stack, Typography, styled } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";

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
    /** Perform the (possibly app specific) logout sequence. */
    logout: () => void;
    showMiniDialog: (attrs: MiniDialogAttributes) => void;
}

export const VerifyingPasskey: React.FC<VerifyingPasskeyProps> = ({
    passkeySessionID,
    email,
    onRetry,
    logout,
    showMiniDialog,
}) => {
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
            else router.push(await saveCredentialsAndNavigateTo(response));
        } catch (e) {
            log.error("Passkey verification status check failed", e);
            showMiniDialog(
                e instanceof Error &&
                    e.message == passkeySessionExpiredErrorMessage
                    ? sessionExpiredDialogAttributes(logout)
                    : genericErrorDialogAttributes(),
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
                        <FocusVisibleButton
                            onClick={handleRetry}
                            fullWidth
                            color="secondary"
                        >
                            {t("try_again")}
                        </FocusVisibleButton>

                        <FocusVisibleButton
                            onClick={handleCheckStatus}
                            fullWidth
                            color="accent"
                        >
                            {t("check_status")}
                        </FocusVisibleButton>
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
 * {@link MiniDialogAttributes} for showing asking the user to login again when
 * their session has expired.
 *
 * There is one button, which allows them to logout.
 *
 * @param onLogin Called when the user presses the "Login" button on the error
 * dialog.
 */
export const sessionExpiredDialogAttributes = (
    onLogin: () => void,
): MiniDialogAttributes => ({
    title: t("session_expired"),
    message: t("session_expired_message"),
    nonClosable: true,
    continue: {
        text: t("login"),
        action: onLogin,
    },
    cancel: false,
});
