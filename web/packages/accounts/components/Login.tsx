import { FormPaperFooter, FormPaperTitle } from "@/base/components/FormPaper";
import { isMuseumHTTPError } from "@/base/http";
import log from "@/base/log";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { LS_KEYS, setData, setLSUser } from "@ente/shared/storage/localStorage";
import { Input, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { PAGES } from "../constants/pages";
import { getSRPAttributes } from "../services/srp-remote";
import { sendOTT } from "../services/user";

interface LoginProps {
    signUp: () => void;
    /** Reactive value of {@link customAPIHost}. */
    host: string | undefined;
}

export const Login: React.FC<LoginProps> = ({ signUp, host }) => {
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
            <FormPaperTitle>{t("login")}</FormPaperTitle>
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
            <FormPaperFooter>
                <Stack sx={{ gap: 4 }}>
                    <LinkButton onClick={signUp}>{t("no_account")}</LinkButton>

                    <Typography
                        variant="mini"
                        sx={{ color: "text.faint", minHeight: "32px" }}
                    >
                        {host ?? "" /* prevent layout shift with a minHeight */}
                    </Typography>
                </Stack>
            </FormPaperFooter>
        </>
    );
};
