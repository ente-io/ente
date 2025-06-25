import { Verify2FACodeForm } from "ente-accounts/components/Verify2FACodeForm";
import type { User } from "ente-accounts/services/user";
import { verifyTwoFactor } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { useBaseContext } from "ente-base/context";
import { isHTTPErrorWithStatus } from "ente-base/http";
import { getData, setData, setLSUser } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "../../components/layouts/centered-paper";
import { unstashRedirect } from "../../services/redirect";

const Page: React.FC = () => {
    const { logout } = useBaseContext();

    const [sessionID, setSessionID] = useState("");

    const router = useRouter();

    useEffect(() => {
        const user: User = getData("user");
        if (!user?.email || !user.twoFactorSessionID) {
            void router.push("/");
        } else if (
            !user.isTwoFactorEnabled &&
            (user.encryptedToken || user.token)
        ) {
            void router.push("/credentials");
        } else {
            setSessionID(user.twoFactorSessionID);
        }
    }, [router]);

    const handleSubmit = async (otp: string) => {
        try {
            const { keyAttributes, encryptedToken, id } = await verifyTwoFactor(
                otp,
                sessionID,
            );
            await setLSUser({
                ...getData("user"),
                id,
                // The original code was parsing an token which is never going
                // to be present in the response, so effectively was always
                // setting token to undefined. So this works, but is it needed?
                token: undefined,
                encryptedToken,
            });
            setData("keyAttributes", keyAttributes);
            await router.push(unstashRedirect() ?? "/credentials");
        } catch (e) {
            if (isHTTPErrorWithStatus(e, 404)) {
                logout();
            } else {
                throw e;
            }
        }
    };

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("two_factor")}</AccountsPageTitle>
            <Verify2FACodeForm
                onSubmit={handleSubmit}
                submitButtonText={t("verify")}
            />
            <AccountsPageFooter>
                <LinkButton onClick={() => router.push("/two-factor/recover")}>
                    {t("lost_2fa_device")}
                </LinkButton>
                <LinkButton onClick={logout}>{t("change_email")}</LinkButton>
            </AccountsPageFooter>
        </AccountsPageContents>
    );
};

export default Page;
