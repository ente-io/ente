import { PAGES } from "@/accounts/constants/pages";
import { verifyTwoFactor } from "@/accounts/services/user";
import {
    FormPaper,
    FormPaperFooter,
    FormPaperTitle,
} from "@/base/components/FormPaper";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
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
    VerifyTwoFactor,
    type VerifyTwoFactorCallback,
} from "../../components/two-factor/VerifyTwoFactor";
import { unstashRedirect } from "../../services/redirect";
import type { PageProps } from "../../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { logout } = appContext;

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
        <VerticallyCentered>
            <FormPaper sx={{ maxWidth: "410px" }}>
                <FormPaperTitle>{t("two_factor")}</FormPaperTitle>
                <VerifyTwoFactor onSubmit={onSubmit} buttonText={t("verify")} />

                <FormPaperFooter sx={{ justifyContent: "space-between" }}>
                    <LinkButton
                        onClick={() => router.push(PAGES.TWO_FACTOR_RECOVER)}
                    >
                        {t("lost_2fa_device")}
                    </LinkButton>
                    <LinkButton onClick={logout}>
                        {t("change_email")}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
