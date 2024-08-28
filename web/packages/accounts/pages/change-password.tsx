import {
    getSRPAttributes,
    startSRPSetup,
    updateSRPAndKeys,
} from "@/accounts/api/srp";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "@/accounts/components/SetPasswordForm";
import { PAGES } from "@/accounts/constants/pages";
import {
    generateSRPClient,
    generateSRPSetupAttributes,
} from "@/accounts/services/srp";
import type { UpdatedKey } from "@/accounts/types/user";
import { convertBase64ToBuffer, convertBufferToBase64 } from "@/accounts/utils";
import { sharedCryptoWorker } from "@/base/crypto";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import {
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { SESSION_KEYS } from "@ente/shared/storage/sessionStorage";
import { getActualKey } from "@ente/shared/user";
import type { KEK, KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { appHomeRoute } from "../services/redirect";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = () => {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();

    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        setUser(user);
        if (!user?.token) {
            InMemoryStore.set(MS_KEYS.REDIRECT_URL, PAGES.CHANGE_PASSWORD);
            router.push("/");
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit: SetPasswordFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        const cryptoWorker = await sharedCryptoWorker();
        const key = await getActualKey();
        const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
        let kek: KEK;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);
        } catch (e) {
            setFieldError("confirm", t("PASSWORD_GENERATION_FAILED"));
            return;
        }
        const encryptedKeyAttributes = await cryptoWorker.encryptToB64(
            key,
            kek.key,
        );
        const updatedKey: UpdatedKey = {
            kekSalt,
            encryptedKey: encryptedKeyAttributes.encryptedData,
            keyDecryptionNonce: encryptedKeyAttributes.nonce,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        };

        const loginSubKey = await generateLoginSubKey(kek.key);

        const { srpUserID, srpSalt, srpVerifier } =
            await generateSRPSetupAttributes(loginSubKey);

        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey,
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        const { setupID, srpB } = await startSRPSetup(ensure(token), {
            srpUserID,
            srpSalt,
            srpVerifier,
            srpA,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        await updateSRPAndKeys(ensure(token), {
            setupID,
            srpM1,
            updatedKeyAttr: updatedKey,
        });

        // Update the SRP attributes that are stored locally.
        if (user?.email) {
            const srpAttributes = await getSRPAttributes(user.email);
            if (srpAttributes) {
                setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
            }
        }

        const updatedKeyAttributes = Object.assign(keyAttributes, updatedKey);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            updatedKeyAttributes,
            key,
        );

        await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);

        redirectToAppHome();
    };

    const redirectToAppHome = () => {
        setData(LS_KEYS.SHOW_BACK_BUTTON, { value: true });
        router.push(appHomeRoute);
    };

    // TODO: Handle the case where user is not loaded yet.
    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t("CHANGE_PASSWORD")}</FormPaperTitle>
                <SetPasswordForm
                    userEmail={user?.email ?? ""}
                    callback={onSubmit}
                    buttonText={t("CHANGE_PASSWORD")}
                />
                {(getData(LS_KEYS.SHOW_BACK_BUTTON)?.value ?? true) && (
                    <FormPaperFooter>
                        <LinkButton onClick={router.back}>
                            {t("GO_BACK")}
                        </LinkButton>
                    </FormPaperFooter>
                )}
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
