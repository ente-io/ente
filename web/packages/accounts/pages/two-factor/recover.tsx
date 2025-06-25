import { Link } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import {
    recoverTwoFactor,
    recoverTwoFactorFinish,
    type TwoFactorRecoveryResponse,
    type TwoFactorType,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { useBaseContext } from "ente-base/context";
import { isHTTP4xxError, isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import { getData } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";

export interface RecoverPageProps {
    twoFactorType: TwoFactorType;
}

/**
 * A page where the user can enter their recovery key to reset or bypass their
 * second factor in case they no longer have access to it.
 */
const Page: React.FC<RecoverPageProps> = ({ twoFactorType }) => {
    const { logout, showMiniDialog, onGenericError } = useBaseContext();

    const [sessionID, setSessionID] = useState<string | undefined>(undefined);
    const [recoveryResponse, setRecoveryResponse] = useState<
        TwoFactorRecoveryResponse | undefined
    >(undefined);

    const router = useRouter();

    const showContactSupportDialog = useCallback(
        (dialogContinue?: MiniDialogAttributes["continue"]) =>
            showMiniDialog({
                title: t("contact_support"),
                message: (
                    <Trans
                        i18nKey={"no_two_factor_recovery_key_message"}
                        components={{
                            a: <Link href="mailto:support@ente.io" />,
                        }}
                        values={{ emailID: "support@ente.io" }}
                    />
                ),
                continue: { color: "secondary", ...(dialogContinue ?? {}) },
                cancel: false,
            }),
        [showMiniDialog],
    );

    useEffect(() => {
        const user = getData("user");
        const sessionID = user.passkeySessionID || user.twoFactorSessionID;
        if (!user?.email || !sessionID) {
            void router.push("/");
        } else if (
            !(user.isTwoFactorEnabled || user.isTwoFactorEnabledPasskey) &&
            (user.encryptedToken || user.token)
        ) {
            void router.push("/generate");
        } else {
            setSessionID(sessionID);
            void recoverTwoFactor(twoFactorType, sessionID)
                .then(setRecoveryResponse)
                .catch((e: unknown) => {
                    log.error("Second factor recovery page setup failed", e);
                    if (isHTTPErrorWithStatus(e, 404)) {
                        logout();
                    } else if (isHTTP4xxError(e)) {
                        showContactSupportDialog({ action: router.back });
                    } else {
                        onGenericError(e);
                    }
                });
        }
    }, [
        twoFactorType,
        logout,
        showContactSupportDialog,
        onGenericError,
        router,
    ]);

    const handleSubmit: SingleInputFormProps["onSubmit"] | undefined = useMemo(
        () =>
            sessionID && recoveryResponse
                ? (recoveryKeyMnemonic, setFieldError) =>
                      recoverTwoFactorFinish(
                          twoFactorType,
                          sessionID,
                          recoveryResponse,
                          recoveryKeyMnemonic,
                      )
                          .then(() => router.push("/credentials"))
                          .catch((e: unknown) => {
                              log.error("Second factor recovery failed", e);
                              setFieldError(t("incorrect_recovery_key"));
                          })
                : undefined,
        [twoFactorType, router, sessionID, recoveryResponse],
    );

    if (!handleSubmit) {
        return <LoadingIndicator />;
    }

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("recover_two_factor")}</AccountsPageTitle>
            <SingleInputForm
                autoComplete="off"
                label={t("recovery_key")}
                submitButtonTitle={t("recover")}
                onSubmit={handleSubmit}
            />
            <AccountsPageFooter>
                <LinkButton onClick={() => showContactSupportDialog()}>
                    {t("no_recovery_key_title")}
                </LinkButton>
                <LinkButton onClick={router.back}>{t("go_back")}</LinkButton>
            </AccountsPageFooter>
        </AccountsPageContents>
    );
};

export default Page;
