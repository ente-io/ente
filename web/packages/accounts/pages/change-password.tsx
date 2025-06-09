import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "ente-accounts/components/SetPasswordForm";
import { appHomeRoute, stashRedirect } from "ente-accounts/services/redirect";
import {
    convertBase64ToBuffer,
    convertBufferToBase64,
    deriveSRPPassword,
    generateSRPClient,
    generateSRPSetupAttributes,
    getSRPAttributes,
    startSRPSetup,
    updateSRPAndKeys,
} from "ente-accounts/services/srp";
import {
    ensureSavedKeyAttributes,
    type UpdatedKey,
    type User,
} from "ente-accounts/services/user";
import { generateAndSaveIntermediateKeyAttributes } from "ente-accounts/utils/helpers";
import { LinkButton } from "ente-base/components/LinkButton";
import { sharedCryptoWorker } from "ente-base/crypto";
import type { DerivedKey } from "ente-base/crypto/types";
import {
    ensureMasterKeyFromSession,
    saveMasterKeyInSessionAndSafeStore,
} from "ente-base/session";
import { getData, setData } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

const Page: React.FC = () => {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();

    const router = useRouter();

    useEffect(() => {
        const user = getData("user");
        setUser(user);
        if (!user?.token) {
            stashRedirect("/change-password");
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
        const masterKey = await ensureMasterKeyFromSession();
        const keyAttributes = ensureSavedKeyAttributes();
        let kek: DerivedKey;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase);
        } catch {
            setFieldError("confirm", t("password_generation_failed"));
            return;
        }
        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await cryptoWorker.encryptBox(masterKey, kek.key);
        const updatedKey: UpdatedKey = {
            encryptedKey,
            keyDecryptionNonce,
            kekSalt: kek.salt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        };

        const loginSubKey = await deriveSRPPassword(kek.key);

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
                setData("srpAttributes", srpAttributes);
            }
        }

        const updatedKeyAttributes = Object.assign(keyAttributes, updatedKey);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            updatedKeyAttributes,
            masterKey,
        );

        await saveMasterKeyInSessionAndSafeStore(masterKey);

        redirectToAppHome();
    };

    const redirectToAppHome = () => {
        setData("showBackButton", { value: true });
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
            {(getData("showBackButton")?.value ?? true) && (
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
