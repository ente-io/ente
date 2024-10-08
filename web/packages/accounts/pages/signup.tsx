import { PAGES } from "@/accounts/constants/pages";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { customAPIHost } from "@/base/origins";
import { LS_KEYS, getData } from "@ente/shared//storage/localStorage";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { SignUp } from "../components/SignUp";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { showNavBar } = appContext;

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

    const login = () => {
        router.push(PAGES.LOGIN);
    };

    return (
        <VerticallyCentered>
            {loading ? (
                <ActivityIndicator />
            ) : (
                <FormPaper>
                    <SignUp {...{ login, router, host }} />
                </FormPaper>
            )}
        </VerticallyCentered>
    );
};

export default Page;
