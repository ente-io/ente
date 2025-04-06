import { Verify2FACodeForm } from "ente-accounts/components/Verify2FACodeForm";
import { verifyTwoFactor } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { useBaseContext } from "ente-base/context";
import { HTTPError } from "ente-base/http";
import { getData, setData, setLSUser } from "ente-shared/storage/localStorage";
import type { User } from "ente-shared/user/types";
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
            const resp = await verifyTwoFactor(otp, sessionID);
            const { keyAttributes, encryptedToken, token, id } = resp;
            await setLSUser({ ...getData("user"), token, encryptedToken, id });
            setData("keyAttributes", keyAttributes!);
            await router.push(unstashRedirect() ?? "/credentials");
        } catch (e) {
            if (e instanceof HTTPError && e.res.status == 404) {
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
