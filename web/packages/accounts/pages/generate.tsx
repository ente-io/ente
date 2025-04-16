import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { RecoveryKey } from "ente-accounts/components/RecoveryKey";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "ente-accounts/components/SetPasswordForm";
import { appHomeRoute } from "ente-accounts/services/redirect";
import {
    configureSRP,
    generateKeyAndSRPAttributes,
} from "ente-accounts/services/srp";
import { putAttributes } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import {
    generateAndSaveIntermediateKeyAttributes,
    saveKeyInSessionStore,
} from "ente-shared/crypto/helpers";
import { getData } from "ente-shared/storage/localStorage";
import {
    justSignedUp,
    setJustSignedUp,
} from "ente-shared/storage/localStorage/helpers";
import { getKey } from "ente-shared/storage/sessionStorage";
import type { KeyAttributes, User } from "ente-shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();
    const [openRecoveryKey, setOpenRecoveryKey] = useState(false);
    const [loading, setLoading] = useState(true);

    const router = useRouter();

    useEffect(() => {
        const key: string = getKey("encryptionKey");
        const keyAttributes: KeyAttributes = getData("originalKeyAttributes");
        const user: User = getData("user");
        setUser(user);
        if (!user?.token) {
            void router.push("/");
        } else if (key) {
            if (justSignedUp()) {
                setOpenRecoveryKey(true);
                setLoading(false);
            } else {
                void router.push(appHomeRoute);
            }
        } else if (keyAttributes?.encryptedKey) {
            void router.push("/credentials");
        } else {
            setToken(user.token);
            setLoading(false);
        }
    }, [router]);

    const onSubmit: SetPasswordFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        try {
            const { keyAttributes, masterKey, srpSetupAttributes } =
                await generateKeyAndSRPAttributes(passphrase);

            // TODO: Refactor the code to not require this ensure
            await putAttributes(token!, keyAttributes);
            await configureSRP(srpSetupAttributes);
            await generateAndSaveIntermediateKeyAttributes(
                passphrase,
                keyAttributes,
                masterKey,
            );
            await saveKeyInSessionStore("encryptionKey", masterKey);
            setJustSignedUp(true);
            setOpenRecoveryKey(true);
        } catch (e) {
            log.error("failed to generate password", e);
            setFieldError("passphrase", t("password_generation_failed"));
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
                    <SetPasswordForm
                        userEmail={user.email}
                        callback={onSubmit}
                        buttonText={t("set_password")}
                    />
                    <AccountsPageFooter>
                        <LinkButton onClick={logout}>{t("go_back")}</LinkButton>
                    </AccountsPageFooter>
                </AccountsPageContents>
            )}
        </>
    );
};

export default Page;
