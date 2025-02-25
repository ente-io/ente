import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "@/accounts/components/layouts/centered-paper";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "@/accounts/components/SetPasswordForm";
import { PAGES } from "@/accounts/constants/pages";
import { appHomeRoute, stashRedirect } from "@/accounts/services/redirect";
import {
    convertBase64ToBuffer,
    convertBufferToBase64,
    generateSRPClient,
    generateSRPSetupAttributes,
} from "@/accounts/services/srp";
import {
    getSRPAttributes,
    startSRPSetup,
    updateSRPAndKeys,
} from "@/accounts/services/srp-remote";
import type { UpdatedKey } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { sharedCryptoWorker } from "@/base/crypto";
import {
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { SESSION_KEYS } from "@ente/shared/storage/sessionStorage";
import { getActualKey } from "@ente/shared/user";
import type { KEK, KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

const Page: React.FC = () => {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();

    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        setUser(user);
        if (!user?.token) {
            stashRedirect(PAGES.CHANGE_PASSWORD);
            void router.push("/");
        } else {
            setToken(user.token);
        }
    }, [router]);

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
        } catch {
            setFieldError("confirm", t("password_generation_failed"));
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

        const { setupID, srpB } = await startSRPSetup(token!, {
            srpUserID,
            srpSalt,
            srpVerifier,
            srpA,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        await updateSRPAndKeys(token!, {
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
        void router.push(appHomeRoute);
    };

    // TODO: Handle the case where user is not loaded yet.
    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("change_password")}</AccountsPageTitle>
            <SetPasswordForm
                userEmail={user?.email ?? ""}
                callback={onSubmit}
                buttonText={t("change_password")}
            />
            {(getData(LS_KEYS.SHOW_BACK_BUTTON)?.value ?? true) && (
                <AccountsPageFooter>
                    <LinkButton onClick={router.back}>
                        {t("go_back")}
                    </LinkButton>
                </AccountsPageFooter>
            )}
        </AccountsPageContents>
    );
};

export default Page;
