import { Verify2FACodeForm } from "@/accounts/components/Verify2FACodeForm";
import { PAGES } from "@/accounts/constants/pages";
import { verifyTwoFactor } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { useBaseContext } from "@/base/context";
import { HTTPError } from "@/base/http";
import {
    LS_KEYS,
    getData,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
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
        const user: User = getData(LS_KEYS.USER);
        if (!user?.email || !user.twoFactorSessionID) {
            void router.push("/");
        } else if (
            !user.isTwoFactorEnabled &&
            (user.encryptedToken || user.token)
        ) {
            void router.push(PAGES.CREDENTIALS);
        } else {
            setSessionID(user.twoFactorSessionID);
        }
    }, [router]);

    const handleSubmit = async (otp: string) => {
        try {
            const resp = await verifyTwoFactor(otp, sessionID);
            const { keyAttributes, encryptedToken, token, id } = resp;
            await setLSUser({
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes!);
            await router.push(unstashRedirect() ?? PAGES.CREDENTIALS);
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
                <LinkButton
                    onClick={() => router.push(PAGES.TWO_FACTOR_RECOVER)}
                >
                    {t("lost_2fa_device")}
                </LinkButton>
                <LinkButton onClick={logout}>{t("change_email")}</LinkButton>
            </AccountsPageFooter>
        </AccountsPageContents>
    );
};

export default Page;
