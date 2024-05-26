import log from "@/next/log";
import type { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { Input } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import type { AppName } from "packages/next/types/app";
import React, { useEffect, useState } from "react";
import { getSRPAttributes } from "../api/srp";
import { sendOtt } from "../api/user";
import { PAGES } from "../constants/pages";
import { appNameToAppNameOld } from "@ente/shared/apps/constants";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { appName, showNavBar } = appContext;

    const [loading, setLoading] = useState(true);

    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        showNavBar(true);
    }, []);

    const register = () => {
        router.push(PAGES.SIGNUP);
    };

    return loading ? (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    ) : (
        <VerticallyCentered>
            <FormPaper>
                <Login signUp={register} appName={appName} />
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;

interface LoginProps {
    signUp: () => void;
    appName: AppName;
}

function Login(props: LoginProps) {
    const router = useRouter();

    const appNameOld = appNameToAppNameOld(props.appName);

    const loginUser: SingleInputFormProps["callback"] = async (
        email,
        setFieldError,
    ) => {
        try {
            setData(LS_KEYS.USER, { email });
            const srpAttributes = await getSRPAttributes(email);
            log.debug(() => ` srpAttributes: ${JSON.stringify(srpAttributes)}`);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                await sendOtt(appNameOld, email);
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
                <LinkButton onClick={props.signUp}>
                    {t("NO_ACCOUNT")}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
