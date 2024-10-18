import log from "@/base/log";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { LS_KEYS, setData, setLSUser } from "@ente/shared/storage/localStorage";
import { Input, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { getSRPAttributes } from "../api/srp";
import { sendOtt } from "../api/user";
import { PAGES } from "../constants/pages";

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
            await setLSUser({ email });
            const srpAttributes = await getSRPAttributes(email);
            log.debug(() => ["srpAttributes", JSON.stringify(srpAttributes)]);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                await sendOtt(email);
                router.push(PAGES.VERIFY);
            } else {
                setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
                router.push(PAGES.CREDENTIALS);
            }
        } catch (e) {
            if (e instanceof Error) {
                setFieldError(
                    `${t("generic_error_retry")} (reason:${e.message})`,
                );
            } else {
                setFieldError(
                    `${t("generic_error_retry")} (reason:${JSON.stringify(e)})`,
                );
            }
        }
    };

    return (
        <>
            <FormPaperTitle>{t("login")}</FormPaperTitle>
            <SingleInputForm
                callback={loginUser}
                fieldType="email"
                placeholder={t("ENTER_EMAIL")}
                buttonText={t("login")}
                autoComplete="username"
                hiddenPostInput={
                    <Input sx={{ display: "none" }} type="password" value="" />
                }
            />

            <FormPaperFooter>
                <Stack gap={4}>
                    <LinkButton onClick={signUp}>{t("NO_ACCOUNT")}</LinkButton>

                    <Typography
                        variant="mini"
                        color="text.faint"
                        minHeight={"32px"}
                    >
                        {host ?? "" /* prevent layout shift with a minHeight */}
                    </Typography>
                </Stack>
            </FormPaperFooter>
        </>
    );
};
