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
    generateSRPSetupAttributes,
    getSRPAttributes,
    updateSRPAndKeyAttributes,
    type UpdatedKeyAttr,
} from "ente-accounts/services/srp";
import {
    ensureSavedKeyAttributes,
    generateAndSaveInteractiveKeyAttributes,
    localUser,
    type LocalUser,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { deriveSensitiveKey, encryptBox } from "ente-base/crypto";
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
    const router = useRouter();

    const onSubmit: SetPasswordFormProps["callback"] = async (
        password,
        setFieldError,
    ) => {
        try {
            await onSubmit2(password);
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

    const onSubmit2 = async (password: string) => {
        const masterKey = await ensureMasterKeyFromSession();
        const keyAttributes = ensureSavedKeyAttributes();

        const {
            key: kek,
            salt: kekSalt,
            opsLimit,
            memLimit,
        } = await deriveSensitiveKey(password);

        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await encryptBox(masterKey, kek);
        const updatedKeyAttr: UpdatedKeyAttr = {
            encryptedKey,
            keyDecryptionNonce,
            kekSalt,
            opsLimit,
            memLimit,
        };

        await updateSRPAndKeyAttributes(
            await generateSRPSetupAttributes(kek),
            updatedKeyAttr,
        );

        // Update the SRP attributes that are stored locally.
        const srpAttributes = await getSRPAttributes(user.email);
        if (srpAttributes) {
            setData("srpAttributes", srpAttributes);
        }

        await generateAndSaveInteractiveKeyAttributes(
            password,
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
