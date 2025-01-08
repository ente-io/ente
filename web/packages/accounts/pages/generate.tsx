import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "@/accounts/components/SetPasswordForm";
import { PAGES } from "@/accounts/constants/pages";
import {
    configureSRP,
    generateKeyAndSRPAttributes,
} from "@/accounts/services/srp";
import { putAttributes } from "@/accounts/services/user";
import {
    FormPaper,
    FormPaperFooter,
    FormPaperTitle,
} from "@/base/components/FormPaper";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
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
import { appHomeRoute } from "../services/redirect";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { logout, showMiniDialog } = appContext;

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
        appContext.showNavBar(true);
    }, []);

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
                <VerticallyCentered>
                    <ActivityIndicator />
                </VerticallyCentered>
            ) : openRecoveryKey ? (
                <RecoveryKey
                    open={openRecoveryKey}
                    onClose={() => {
                        setOpenRecoveryKey(false);
                        void router.push(appHomeRoute);
                    }}
                    showMiniDialog={showMiniDialog}
                />
            ) : (
                <VerticallyCentered>
                    <FormPaper>
                        <FormPaperTitle>{t("set_password")}</FormPaperTitle>
                        <SetPasswordForm
                            userEmail={user.email}
                            callback={onSubmit}
                            buttonText={t("set_password")}
                        />
                        <FormPaperFooter>
                            <LinkButton onClick={logout}>
                                {t("go_back")}
                            </LinkButton>
                        </FormPaperFooter>
                    </FormPaper>
                </VerticallyCentered>
            )}
        </>
    );
};

export default Page;
