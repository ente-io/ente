import { PAGES } from "@/accounts/constants/pages";
import { sendOTT } from "@/accounts/services/user";
import {
    FormPaper,
    FormPaperFooter,
    FormPaperTitle,
} from "@/base/components/FormPaper";
import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import {
    decryptAndStoreToken,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { SESSION_KEYS, getKey } from "@ente/shared/storage/sessionStorage";
import type { KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { appHomeRoute, stashRedirect } from "../services/redirect";
import type { PageProps } from "../types/page";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const bip39 = require("bip39");
// mobile client library only supports english.
bip39.setDefaultWordlist("english");

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { showNavBar, showMiniDialog } = appContext;

    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        const user: User = getData(LS_KEYS.USER);
        const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!user?.email) {
            void router.push("/");
            return;
        }
        if (!user?.encryptedToken && !user?.token) {
            void sendOTT(user.email, undefined);
            stashRedirect(PAGES.RECOVER);
            void router.push(PAGES.VERIFY);
            return;
        }
        if (!keyAttributes) {
            void router.push(PAGES.GENERATE);
        } else if (key) {
            void router.push(appHomeRoute);
        } else {
            setKeyAttributes(keyAttributes);
        }
        showNavBar(true);
    }, []);

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
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            await decryptAndStoreToken(keyAttr, masterKey);

            setData(LS_KEYS.SHOW_BACK_BUTTON, { value: false });
            void router.push(PAGES.CHANGE_PASSWORD);
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
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t("recover_account")}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={t("recovery_key")}
                    buttonText={t("recover")}
                    disableAutoComplete
                />
                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton onClick={showNoRecoveryKeyMessage}>
                        {t("no_recovery_key_title")}
                    </LinkButton>
                    <LinkButton onClick={router.back}>
                        {t("go_back")}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
