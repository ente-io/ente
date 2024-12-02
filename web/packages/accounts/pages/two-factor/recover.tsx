import { PAGES } from "@/accounts/constants/pages";
import {
    recoverTwoFactor,
    removeTwoFactor,
    type TwoFactorType,
} from "@/accounts/services/user";
import type { AccountsContextT } from "@/accounts/types/context";
import {
    FormPaper,
    FormPaperFooter,
    FormPaperTitle,
} from "@/base/components/FormPaper";
import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { sharedCryptoWorker } from "@/base/crypto";
import type { B64EncryptionResult } from "@/base/crypto/libsodium";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { ApiError } from "@ente/shared/error";
import {
    LS_KEYS,
    getData,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import { Link } from "@mui/material";
import { HttpStatusCode } from "axios";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const bip39 = require("bip39");
// mobile client library only supports english.
bip39.setDefaultWordlist("english");

export interface RecoverPageProps {
    appContext: AccountsContextT;
    twoFactorType: TwoFactorType;
}

const Page: React.FC<RecoverPageProps> = ({ appContext, twoFactorType }) => {
    const { showMiniDialog, logout } = appContext;

    const [encryptedTwoFactorSecret, setEncryptedTwoFactorSecret] =
        useState<Omit<B64EncryptionResult, "key"> | null>(null);
    const [sessionID, setSessionID] = useState<string | null>(null);
    const [doesHaveEncryptedRecoveryKey, setDoesHaveEncryptedRecoveryKey] =
        useState(false);

    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        const sid = user.passkeySessionID || user.twoFactorSessionID;
        if (!user?.email || !sid) {
            void router.push("/");
        } else if (
            !(user.isTwoFactorEnabled || user.isTwoFactorEnabledPasskey) &&
            (user.encryptedToken || user.token)
        ) {
            void router.push(PAGES.GENERATE);
        } else {
            setSessionID(sid);
        }
        const main = async () => {
            try {
                const resp = await recoverTwoFactor(sid, twoFactorType);
                setDoesHaveEncryptedRecoveryKey(!!resp.encryptedSecret);
                if (!resp.encryptedSecret) {
                    showContactSupportDialog({ action: router.back });
                } else {
                    setEncryptedTwoFactorSecret({
                        encryptedData: resp.encryptedSecret,
                        nonce: resp.secretDecryptionNonce,
                    });
                }
            } catch (e) {
                if (
                    e instanceof ApiError &&
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
                    e.httpStatusCode === HttpStatusCode.NotFound
                ) {
                    logout();
                } else {
                    log.error("two factor recovery page setup failed", e);
                    setDoesHaveEncryptedRecoveryKey(false);
                    showContactSupportDialog({ action: router.back });
                }
            }
        };
        void main();
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
            const { encryptedData, nonce } = encryptedTwoFactorSecret!;
            const twoFactorSecret = await cryptoWorker.decryptB64(
                encryptedData,
                nonce,
                await cryptoWorker.fromHex(recoveryKey),
            );
            const resp = await removeTwoFactor(
                sessionID!,
                twoFactorSecret,
                twoFactorType,
            );
            const { keyAttributes, encryptedToken, token, id } = resp;
            await setLSUser({
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
                isTwoFactorEnabled: false,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            void router.push(PAGES.CREDENTIALS);
        } catch (e) {
            log.error("two factor recovery failed", e);
            setFieldError(t("INCORRECT_RECOVERY_KEY"));
        }
    };

    const showContactSupportDialog = (
        dialogContinue?: MiniDialogAttributes["continue"],
    ) => {
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
        });
    };

    if (!doesHaveEncryptedRecoveryKey) {
        return <></>;
    }

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t("RECOVER_TWO_FACTOR")}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={t("RECOVERY_KEY_HINT")}
                    buttonText={t("RECOVER")}
                    disableAutoComplete
                />
                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton onClick={() => showContactSupportDialog()}>
                        {t("NO_RECOVERY_KEY")}
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
