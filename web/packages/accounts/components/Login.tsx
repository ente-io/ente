import log from "@/next/log";
import type { AppName } from "@/next/types/app";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { LS_KEYS, setData } from "@ente/shared/storage/localStorage";
import { Input, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { getSRPAttributes } from "../api/srp";
import { sendOtt } from "../api/user";
import { PAGES } from "../constants/pages";

interface LoginProps {
    signUp: () => void;
    appName: AppName;
    /** Reactive value of {@link customAPIHost}. */
    host: string | undefined;
}

export function Login({ appName, signUp, host }: LoginProps) {
    const router = useRouter();

    const loginUser: SingleInputFormProps["callback"] = async (
        email,
        setFieldError,
    ) => {
        try {
            setData(LS_KEYS.USER, { email });
            const srpAttributes = await getSRPAttributes(email);
            log.debug(() => ` srpAttributes: ${JSON.stringify(srpAttributes)}`);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                await sendOtt(appName, email);
                router.push(PAGES.VERIFY);
            } else {
                setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
                router.push(PAGES.CREDENTIALS);
            }
        } catch (e) {
            if (e instanceof Error) {
                setFieldError(`${t("UNKNOWN_ERROR")} (reason:${e.message})`);
            } else {
                setFieldError(
                    `${t("UNKNOWN_ERROR")} (reason:${JSON.stringify(e)})`,
                );
            }
        }
    };

    return (
        <>
            <FormPaperTitle>{t("LOGIN")}</FormPaperTitle>
            <SingleInputForm
                callback={loginUser}
                fieldType="email"
                placeholder={t("ENTER_EMAIL")}
                buttonText={t("LOGIN")}
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
}
