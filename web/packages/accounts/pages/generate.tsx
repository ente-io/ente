import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "@/accounts/components/layouts/centered-paper";
import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "@/accounts/components/SetPasswordForm";
import { PAGES } from "@/accounts/constants/pages";
import { appHomeRoute } from "@/accounts/services/redirect";
import {
    configureSRP,
    generateKeyAndSRPAttributes,
} from "@/accounts/services/srp";
import { putAttributes } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { LoadingIndicator } from "@/base/components/loaders";
import { useBaseContext } from "@/base/context";
import log from "@/base/log";
import {
    generateAndSaveIntermediateKeyAttributes,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import {
    justSignedUp,
    setJustSignedUp,
} from "@ente/shared/storage/localStorage/helpers";
import { SESSION_KEYS, getKey } from "@ente/shared/storage/sessionStorage";
import type { KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";

const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();
    const [openRecoveryKey, setOpenRecoveryKey] = useState(false);
    const [loading, setLoading] = useState(true);

    const router = useRouter();

    useEffect(() => {
        const key: string = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        const keyAttributes: KeyAttributes = getData(
            LS_KEYS.ORIGINAL_KEY_ATTRIBUTES,
        );
        const user: User = getData(LS_KEYS.USER);
        setUser(user);
        if (!user?.token) {
            void router.push("/");
        } else if (key) {
            if (justSignedUp()) {
                setOpenRecoveryKey(true);
                setLoading(false);
            } else {
                void router.push(appHomeRoute);
            }
        } else if (keyAttributes?.encryptedKey) {
            void router.push(PAGES.CREDENTIALS);
        } else {
            setToken(user.token);
            setLoading(false);
        }
    }, [router]);

    const onSubmit: SetPasswordFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        try {
            const { keyAttributes, masterKey, srpSetupAttributes } =
                await generateKeyAndSRPAttributes(passphrase);

            // TODO: Refactor the code to not require this ensure
            await putAttributes(token!, keyAttributes);
            await configureSRP(srpSetupAttributes);
            await generateAndSaveIntermediateKeyAttributes(
                passphrase,
                keyAttributes,
                masterKey,
            );
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            setJustSignedUp(true);
            setOpenRecoveryKey(true);
        } catch (e) {
            log.error("failed to generate password", e);
            setFieldError("passphrase", t("password_generation_failed"));
        }
    };

    return (
        <>
            {loading || !user ? (
                <LoadingIndicator />
            ) : openRecoveryKey ? (
                <RecoveryKey
                    open={openRecoveryKey}
                    onClose={() => void router.push(appHomeRoute)}
                    showMiniDialog={showMiniDialog}
                />
            ) : (
                <AccountsPageContents>
                    <AccountsPageTitle>{t("set_password")}</AccountsPageTitle>
                    <SetPasswordForm
                        userEmail={user.email}
                        callback={onSubmit}
                        buttonText={t("set_password")}
                    />
                    <AccountsPageFooter>
                        <LinkButton onClick={logout}>{t("go_back")}</LinkButton>
                    </AccountsPageFooter>
                </AccountsPageContents>
            )}
        </>
    );
};

export default Page;
