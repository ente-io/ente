import { PAGES } from "@/accounts/constants/pages";
import { verifyTwoFactor } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { useBaseContext } from "@/base/context";
import { ApiError } from "@ente/shared/error";
import {
    LS_KEYS,
    getData,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { HttpStatusCode } from "axios";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "../../components/layouts/centered-paper";
import {
    VerifyTwoFactor,
    type VerifyTwoFactorCallback,
} from "../../components/two-factor/VerifyTwoFactor";
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
    }, []);

    const onSubmit: VerifyTwoFactorCallback = async (otp) => {
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
            void router.push(unstashRedirect() ?? PAGES.CREDENTIALS);
        } catch (e) {
            if (
                e instanceof ApiError &&
                // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
                e.httpStatusCode === HttpStatusCode.NotFound
            ) {
                logout();
            } else {
                throw e;
            }
        }
    };

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("two_factor")}</AccountsPageTitle>
            <VerifyTwoFactor onSubmit={onSubmit} buttonText={t("verify")} />
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
