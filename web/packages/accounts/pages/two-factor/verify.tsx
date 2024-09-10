import { verifyTwoFactor } from "@/accounts/api/user";
import VerifyTwoFactor, {
    type VerifyTwoFactorCallback,
} from "@/accounts/components/two-factor/VerifyForm";
import { PAGES } from "@/accounts/constants/pages";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormTitle from "@ente/shared/components/Form/FormPaper/Title";
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
import { unstashRedirect } from "../../services/redirect";
import type { PageProps } from "../../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { logout } = appContext;

    const [sessionID, setSessionID] = useState("");

    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email || !user.twoFactorSessionID) {
                router.push("/");
            } else if (
                !user.isTwoFactorEnabled &&
                (user.encryptedToken || user.token)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setSessionID(user.twoFactorSessionID);
            }
        };
        main();
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
            setData(LS_KEYS.KEY_ATTRIBUTES, ensure(keyAttributes));
            router.push(unstashRedirect() ?? PAGES.CREDENTIALS);
        } catch (e) {
            if (
                e instanceof ApiError &&
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
                <FormTitle>{t("TWO_FACTOR")}</FormTitle>
                <VerifyTwoFactor onSubmit={onSubmit} buttonText={t("VERIFY")} />

                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton
                        onClick={() => router.push(PAGES.TWO_FACTOR_RECOVER)}
                    >
                        {t("LOST_DEVICE")}
                    </LinkButton>
                    <LinkButton onClick={logout}>
                        {t("CHANGE_EMAIL")}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
