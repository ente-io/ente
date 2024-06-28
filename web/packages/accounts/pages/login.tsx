import { customAPIHost } from "@/next/origins";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { Login } from "../components/Login";
import { PAGES } from "../constants/pages";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { appName, showNavBar } = appContext;

    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        void customAPIHost().then(setHost);
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        showNavBar(true);
    }, []);

    const signUp = () => {
        router.push(PAGES.SIGNUP);
    };

    return loading ? (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    ) : (
        <VerticallyCentered>
            <FormPaper>
                <Login {...{ appName, signUp, host }} />
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
