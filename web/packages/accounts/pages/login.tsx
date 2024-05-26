import type { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { Login } from "../components/Login";
import { PAGES } from "../constants/pages";

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
