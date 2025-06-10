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
    type UpdatedKeyAttr,
} from "ente-accounts/services/srp";
import {
    ensureSavedKeyAttributes,
    localUser,
    type LocalUser,
} from "ente-accounts/services/user";
import { generateAndSaveIntermediateKeyAttributes } from "ente-accounts/utils/helpers";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { sharedCryptoWorker } from "ente-base/crypto";
import { deriveKeyInsufficientMemoryErrorMessage } from "ente-base/crypto/types";
import log from "ente-base/log";
import {
    ensureMasterKeyFromSession,
    saveMasterKeyInSessionAndSafeStore,
} from "ente-base/session";
import { getData, setData } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";

/**
 * A page that allows a user to reset or change their password.
 */
const Page: React.FC = () => {
    const [user, setUser] = useState<LocalUser>();

    const router = useRouter();

    useEffect(() => {
        const user = localUser();
        if (user) {
            setUser(user);
        } else {
            stashRedirect("/change-password");
            void router.push("/");
        }
    }, [router]);

    return user ? <PageContents {...{ user }} /> : <LoadingIndicator />;
};

export default Page;

interface PageContentsProps {
    user: LocalUser;
}

const PageContents: React.FC<PageContentsProps> = ({ user }) => {
    const token = user.token;

    const router = useRouter();

    const onSubmit: SetPasswordFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        try {
            await onSubmit2(passphrase);
        } catch (e) {
            log.error("Could not change password", e);
            setFieldError(
                "confirm",
                e instanceof Error &&
                    e.message == deriveKeyInsufficientMemoryErrorMessage
                    ? t("password_generation_failed")
                    : t("generic_error"),
            );
        }
    };

    const onSubmit2 = async (passphrase: string) => {
        const cryptoWorker = await sharedCryptoWorker();
        const masterKey = await ensureMasterKeyFromSession();
        const keyAttributes = ensureSavedKeyAttributes();
        const {
            key: kek,
            salt: kekSalt,
            opsLimit,
            memLimit,
        } = await cryptoWorker.deriveSensitiveKey(passphrase);
        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await cryptoWorker.encryptBox(masterKey, kek);
        const updatedKeyAttr: UpdatedKeyAttr = {
            encryptedKey,
            keyDecryptionNonce,
            kekSalt,
            opsLimit,
            memLimit,
        };

        const loginSubKey = await deriveSRPPassword(kek);

        const { srpUserID, srpSalt, srpVerifier } =
            await generateSRPSetupAttributes(loginSubKey);

        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey,
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        const { setupID, srpB } = await startSRPSetup(token, {
            srpUserID,
            srpSalt,
            srpVerifier,
            srpA,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        await updateSRPAndKeys(token, { setupID, srpM1, updatedKeyAttr });

        // Update the SRP attributes that are stored locally.
        const srpAttributes = await getSRPAttributes(user.email);
        if (srpAttributes) {
            setData("srpAttributes", srpAttributes);
        }

        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            { ...keyAttributes, ...updatedKeyAttr },
            masterKey,
        );

        await saveMasterKeyInSessionAndSafeStore(masterKey);

        redirectToAppHome();
    };

    const redirectToAppHome = () => {
        setData("showBackButton", { value: true });
        void router.push(appHomeRoute);
    };

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("change_password")}</AccountsPageTitle>
            <SetPasswordForm
                userEmail={user.email}
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
