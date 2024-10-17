import { putAttributes } from "@/accounts/api/user";
import { RecoveryKey } from "@/accounts/components/RecoveryKey";
import SetPasswordForm, {
    type SetPasswordFormProps,
} from "@/accounts/components/SetPasswordForm";
import { PAGES } from "@/accounts/constants/pages";
import { configureSRP } from "@/accounts/services/srp";
import { generateKeyAndSRPAttributes } from "@/accounts/utils/srp";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormTitle from "@ente/shared/components/Form/FormPaper/Title";
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
        const main = async () => {
            const key: string = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.ORIGINAL_KEY_ATTRIBUTES,
            );
            const user: User = getData(LS_KEYS.USER);
            setUser(user);
            if (!user?.token) {
                router.push("/");
            } else if (key) {
                if (justSignedUp()) {
                    setOpenRecoveryKey(true);
                    setLoading(false);
                } else {
                    router.push(appHomeRoute);
                }
            } else if (keyAttributes?.encryptedKey) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setToken(user.token);
                setLoading(false);
            }
        };
        main();
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
            await putAttributes(ensure(token), keyAttributes);
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
            setFieldError("passphrase", t("PASSWORD_GENERATION_FAILED"));
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
                        router.push(appHomeRoute);
                    }}
                    showMiniDialog={showMiniDialog}
                />
            ) : (
                <VerticallyCentered>
                    <FormPaper>
                        <FormTitle>{t("SET_PASSPHRASE")}</FormTitle>
                        <SetPasswordForm
                            userEmail={user.email}
                            callback={onSubmit}
                            buttonText={t("SET_PASSPHRASE")}
                        />
                        <FormPaperFooter>
                            <LinkButton onClick={logout}>
                                {t("GO_BACK")}
                            </LinkButton>
                        </FormPaperFooter>
                    </FormPaper>
                </VerticallyCentered>
            )}
        </>
    );
};

export default Page;
