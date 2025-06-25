import { Divider } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { RecoveryKey } from "ente-accounts/components/RecoveryKey";
import { appHomeRoute } from "ente-accounts/services/redirect";
import {
    generateSRPSetupAttributes,
    setupSRP,
} from "ente-accounts/services/srp";
import type { KeyAttributes, User } from "ente-accounts/services/user";
import {
    generateAndSaveInteractiveKeyAttributes,
    generateKeysAndAttributes,
    putUserKeyAttributes,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import { deriveKeyInsufficientMemoryErrorMessage } from "ente-base/crypto/types";
import log from "ente-base/log";
import {
    haveCredentialsInSession,
    saveMasterKeyInSessionAndSafeStore,
} from "ente-base/session";
import { getData } from "ente-shared/storage/localStorage";
import {
    justSignedUp,
    setJustSignedUp,
} from "ente-shared/storage/localStorage/helpers";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    NewPasswordForm,
    type NewPasswordFormProps,
} from "../components/NewPasswordForm";

const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [user, setUser] = useState<User>();
    const [openRecoveryKey, setOpenRecoveryKey] = useState(false);
    const [loading, setLoading] = useState(true);

    const router = useRouter();

    useEffect(() => {
        const keyAttributes: KeyAttributes = getData("originalKeyAttributes");
        const user: User = getData("user");
        setUser(user);
        if (!user?.token) {
            void router.push("/");
        } else if (haveCredentialsInSession()) {
            if (justSignedUp()) {
                setOpenRecoveryKey(true);
                setLoading(false);
            } else {
                void router.push(appHomeRoute);
            }
        } else if (keyAttributes?.encryptedKey) {
            void router.push("/credentials");
        } else {
            setLoading(false);
        }
    }, [router]);

    const handleSubmit: NewPasswordFormProps["onSubmit"] = async (
        password,
        setPasswordsFieldError,
    ) => {
        try {
            const { masterKey, kek, keyAttributes } =
                await generateKeysAndAttributes(password);
            await putUserKeyAttributes(keyAttributes);
            await setupSRP(await generateSRPSetupAttributes(kek));
            await generateAndSaveInteractiveKeyAttributes(
                password,
                keyAttributes,
                masterKey,
            );
            await saveMasterKeyInSessionAndSafeStore(masterKey);
            setJustSignedUp(true);
            setOpenRecoveryKey(true);
        } catch (e) {
            log.error("failed to generate password", e);
            setPasswordsFieldError(
                e instanceof Error &&
                    e.message == deriveKeyInsufficientMemoryErrorMessage
                    ? t("password_generation_failed")
                    : t("generic_error"),
            );
        }
    };

    return (
        <>
            {loading || !user ? (
                <LoadingIndicator />
            ) : openRecoveryKey ? (
                <RecoveryKey
                    open={openRecoveryKey}
                    onClose={() => void router.push(appHomeRoute)}
                    showMiniDialog={showMiniDialog}
                />
            ) : (
                <AccountsPageContents>
                    <AccountsPageTitle>{t("set_password")}</AccountsPageTitle>
                    <NewPasswordForm
                        userEmail={user.email}
                        submitButtonTitle={t("set_password")}
                        onSubmit={handleSubmit}
                    />
                    <Divider sx={{ mt: 1 }} />
                    <AccountsPageFooter>
                        <LinkButton onClick={logout}>{t("go_back")}</LinkButton>
                    </AccountsPageFooter>
                </AccountsPageContents>
            )}
        </>
    );
};

export default Page;
