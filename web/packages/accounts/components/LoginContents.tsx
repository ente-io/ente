import {
    AccountsPageFooter,
    AccountsPageTitle,
} from "@/accounts/components/layouts/centered-paper";
import { PAGES } from "@/accounts/constants/pages";
import { getSRPAttributes } from "@/accounts/services/srp-remote";
import { sendOTT } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { isMuseumHTTPError } from "@/base/http";
import log from "@/base/log";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { LS_KEYS, setData, setLSUser } from "@ente/shared/storage/localStorage";
import { Input, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";

interface LoginContentsProps {
    /** Called when the user clicks the signup option instead.  */
    onSignUp: () => void;
    /** Reactive value of {@link customAPIHost}. */
    host: string | undefined;
}

/**
 * Contents of the "login form", maintained as a separate component so that the
 * same code can be used both in the standalone /login page, and also within the
 * embedded login form shown on the photos index page.
 */
export const LoginContents: React.FC<LoginContentsProps> = ({
    onSignUp,
    host,
}) => {
    const router = useRouter();

    const loginUser: SingleInputFormProps["callback"] = async (
        email,
        setFieldError,
    ) => {
        try {
            const srpAttributes = await getSRPAttributes(email);
            log.debug(() => ["srpAttributes", JSON.stringify(srpAttributes)]);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                try {
                    await sendOTT(email, "login");
                } catch (e) {
                    if (
                        await isMuseumHTTPError(e, 404, "USER_NOT_REGISTERED")
                    ) {
                        setFieldError(t("email_not_registered"));
                        return;
                    }
                    throw e;
                }
                await setLSUser({ email });
                void router.push(PAGES.VERIFY);
            } else {
                await setLSUser({ email });
                setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
                void router.push(PAGES.CREDENTIALS);
            }
        } catch (e) {
            log.error("Login failed", e);
            setFieldError(t("generic_error"));
        }
    };

    return (
        <>
            <AccountsPageTitle>{t("login")}</AccountsPageTitle>
            <SingleInputForm
                callback={loginUser}
                fieldType="email"
                placeholder={t("enter_email")}
                buttonText={t("login")}
                autoComplete="username"
                hiddenPostInput={
                    <Input sx={{ display: "none" }} type="password" value="" />
                }
            />
            <AccountsPageFooter>
                <Stack sx={{ gap: 3, textAlign: "center" }}>
                    <LinkButton onClick={onSignUp}>
                        {t("no_account")}
                    </LinkButton>
                    <Typography
                        variant="mini"
                        sx={{ color: "text.faint", minHeight: "16px" }}
                    >
                        {host ?? "" /* prevent layout shift with a minHeight */}
                    </Typography>
                </Stack>
            </AccountsPageFooter>
        </>
    );
};
