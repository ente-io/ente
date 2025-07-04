import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import {
    savedKeyAttributes,
    savedPartialLocalUser,
} from "ente-accounts/services/accounts-db";
import { recoveryKeyFromMnemonic } from "ente-accounts/services/recovery-key";
import { appHomeRoute, stashRedirect } from "ente-accounts/services/redirect";
import type { KeyAttributes } from "ente-accounts/services/user";
import { sendOTT } from "ente-accounts/services/user";
import { decryptAndStoreToken } from "ente-accounts/utils/helpers";
import { LinkButton } from "ente-base/components/LinkButton";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { useBaseContext } from "ente-base/context";
import { decryptBox } from "ente-base/crypto";
import log from "ente-base/log";
import {
    haveMasterKeyInSession,
    saveMasterKeyInSessionAndSafeStore,
} from "ente-base/session";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

/**
 * A page that allows the user to enter their recovery key to recover their
 * master key if they've forgotten their password.
 *
 * See: [Note: Login pages]
 */
const Page: React.FC = () => {
    const { showMiniDialog } = useBaseContext();

    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >(undefined);

    const router = useRouter();

    useEffect(() => {
        const user = savedPartialLocalUser();
        if (!user?.email) {
            void router.push("/");
            return;
        }
        if (!user?.encryptedToken && !user?.token) {
            void sendOTT(user.email, undefined);
            stashRedirect("/recover");
            void router.push("/verify");
            return;
        }

        const keyAttributes = savedKeyAttributes();
        if (!keyAttributes) {
            void router.push("/generate");
        } else if (haveMasterKeyInSession()) {
            void router.push(appHomeRoute);
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, [router]);

    const handleSubmit: SingleInputFormProps["onSubmit"] = async (
        recoveryKeyMnemonic: string,
        setFieldError,
    ) => {
        try {
            const keyAttr = keyAttributes!;
            const masterKey = await decryptBox(
                {
                    encryptedData: keyAttr.masterKeyEncryptedWithRecoveryKey!,
                    nonce: keyAttr.masterKeyDecryptionNonce!,
                },
                await recoveryKeyFromMnemonic(recoveryKeyMnemonic),
            );
            await saveMasterKeyInSessionAndSafeStore(masterKey);
            await decryptAndStoreToken(keyAttr, masterKey);

            void router.push("/change-password?op=reset");
        } catch (e) {
            log.error("password recovery failed", e);
            setFieldError(t("incorrect_recovery_key"));
        }
    };

    const showNoRecoveryKeyMessage = () =>
        showMiniDialog({
            title: t("sorry"),
            message: t("no_recovery_key_message"),
            continue: { color: "secondary" },
            cancel: false,
        });

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("recover_account")}</AccountsPageTitle>
            <SingleInputForm
                autoComplete="off"
                label={t("recovery_key")}
                submitButtonTitle={t("recover")}
                onSubmit={handleSubmit}
            />
            <AccountsPageFooter>
                <LinkButton onClick={showNoRecoveryKeyMessage}>
                    {t("no_recovery_key_title")}
                </LinkButton>
                <LinkButton onClick={router.back}>{t("go_back")}</LinkButton>
            </AccountsPageFooter>
        </AccountsPageContents>
    );
};

export default Page;
