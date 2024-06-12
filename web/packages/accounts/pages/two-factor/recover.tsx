import log from "@/next/log";
import type { BaseAppContextT } from "@/next/types/app";
import { ensure } from "@/utils/ensure";
import {
    recoverTwoFactor,
    removeTwoFactor,
    type TwoFactorType,
} from "@ente/accounts/api/user";
import { PAGES } from "@ente/accounts/constants/pages";
import { VerticallyCentered } from "@ente/shared/components/Container";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { SUPPORT_EMAIL } from "@ente/shared/constants/urls";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import type { B64EncryptionResult } from "@ente/shared/crypto/types";
import { ApiError } from "@ente/shared/error";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { Link } from "@mui/material";
import { HttpStatusCode } from "axios";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";

const bip39 = require("bip39");
// mobile client library only supports english.
bip39.setDefaultWordlist("english");

export interface RecoverPageProps {
    appContext: BaseAppContextT;
    twoFactorType: TwoFactorType;
}

const Page: React.FC<RecoverPageProps> = ({ appContext, twoFactorType }) => {
    const { logout } = appContext;

    const [encryptedTwoFactorSecret, setEncryptedTwoFactorSecret] =
        useState<Omit<B64EncryptionResult, "key"> | null>(null);
    const [sessionID, setSessionID] = useState<string | null>(null);
    const [doesHaveEncryptedRecoveryKey, setDoesHaveEncryptedRecoveryKey] =
        useState(false);

    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        const sid = user.passkeySessionID || user.twoFactorSessionID;
        if (!user || !user.email || !sid) {
            router.push(PAGES.ROOT);
        } else if (
            !(user.isTwoFactorEnabled || user.isTwoFactorEnabledPasskey) &&
            (user.encryptedToken || user.token)
        ) {
            router.push(PAGES.GENERATE);
        } else {
            setSessionID(sid);
        }
        const main = async () => {
            try {
                const resp = await recoverTwoFactor(sid, twoFactorType);
                setDoesHaveEncryptedRecoveryKey(!!resp.encryptedSecret);
                if (!resp.encryptedSecret) {
                    showContactSupportDialog({
                        text: t("GO_BACK"),
                        action: router.back,
                    });
                } else {
                    setEncryptedTwoFactorSecret({
                        encryptedData: resp.encryptedSecret,
                        nonce: resp.secretDecryptionNonce,
                    });
                }
            } catch (e) {
                if (
                    e instanceof ApiError &&
                    e.httpStatusCode === HttpStatusCode.NotFound
                ) {
                    logout();
                } else {
                    log.error("two factor recovery page setup failed", e);
                    setDoesHaveEncryptedRecoveryKey(false);
                    showContactSupportDialog({
                        text: t("GO_BACK"),
                        action: router.back,
                    });
                }
            }
        };
        main();
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
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
            const { encryptedData, nonce } = ensure(encryptedTwoFactorSecret);
            const twoFactorSecret = await cryptoWorker.decryptB64(
                encryptedData,
                nonce,
                await cryptoWorker.fromHex(recoveryKey),
            );
            const resp = await removeTwoFactor(
                ensure(sessionID),
                twoFactorSecret,
                twoFactorType,
            );
            const { keyAttributes, encryptedToken, token, id } = resp;
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
                isTwoFactorEnabled: false,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            log.error("two factor recovery failed", e);
            setFieldError(t("INCORRECT_RECOVERY_KEY"));
        }
    };

    const showContactSupportDialog = (
        dialogClose?: DialogBoxAttributesV2["close"],
    ) => {
        appContext.setDialogBoxAttributesV2({
            title: t("CONTACT_SUPPORT"),
            close: dialogClose ?? {},
            content: (
                <Trans
                    i18nKey={"NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE"}
                    values={{ emailID: SUPPORT_EMAIL }}
                    components={{
                        a: <Link href={`mailto:${SUPPORT_EMAIL}`} />,
                    }}
                />
            ),
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
                        {t("GO_BACK")}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
