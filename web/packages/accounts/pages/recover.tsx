import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { appHomeRoute, stashRedirect } from "ente-accounts/services/redirect";
import { sendOTT } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { useBaseContext } from "ente-base/context";
import { sharedCryptoWorker } from "ente-base/crypto";
import log from "ente-base/log";
import SingleInputForm, {
    type SingleInputFormProps,
} from "ente-shared/components/SingleInputForm";
import {
    decryptAndStoreToken,
    saveKeyInSessionStore,
} from "ente-shared/crypto/helpers";
import { getData, setData } from "ente-shared/storage/localStorage";
import { getKey } from "ente-shared/storage/sessionStorage";
import type { KeyAttributes, User } from "ente-shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const bip39 = require("bip39");
// mobile client library only supports english.
bip39.setDefaultWordlist("english");

const Page: React.FC = () => {
    const { showMiniDialog } = useBaseContext();

    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        const user: User = getData("user");
        const keyAttributes: KeyAttributes = getData("keyAttributes");
        const key = getKey("encryptionKey");
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
        if (!keyAttributes) {
            void router.push("/generate");
        } else if (key) {
            void router.push(appHomeRoute);
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, [router]);

    const recover: SingleInputFormProps["callback"] = async (
        recoveryKey: string,
        setFieldError,
    ) => {
        try {
            recoveryKey = recoveryKey
                .trim()
                .split(" ")
                .map((part) => part.trim())
                .filter((part) => !!part)
                .join(" ");
            // check if user is entering mnemonic recovery key
            if (recoveryKey.indexOf(" ") > 0) {
                if (recoveryKey.split(" ").length !== 24) {
                    throw new Error("recovery code should have 24 words");
                }
                recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
            }
            const cryptoWorker = await sharedCryptoWorker();
            const keyAttr = keyAttributes!;
            const masterKey = await cryptoWorker.decryptB64(
                keyAttr.masterKeyEncryptedWithRecoveryKey!,
                keyAttr.masterKeyDecryptionNonce!,
                await cryptoWorker.fromHex(recoveryKey),
            );
            await saveKeyInSessionStore("encryptionKey", masterKey);
            await decryptAndStoreToken(keyAttr, masterKey);

            setData("showBackButton", { value: false });
            void router.push("/change-password");
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
                callback={recover}
                fieldType="text"
                placeholder={t("recovery_key")}
                buttonText={t("recover")}
                disableAutoComplete
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
