import { Stack100vhCenter } from "@/base/components/containers";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { customAPIHost } from "@/base/origins";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import { AccountsPageContents } from "../components/layouts/centered-paper";
import { Login } from "../components/Login";
import { PAGES } from "../constants/pages";

const Page: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        void customAPIHost().then(setHost);
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            void router.push(PAGES.VERIFY);
        }
        setLoading(false);
    }, []);

    const signUp = () => {
        void router.push(PAGES.SIGNUP);
    };

    return loading ? (
        <Stack100vhCenter>
            <ActivityIndicator />
        </Stack100vhCenter>
    ) : (
        <AccountsPageContents>
            <Login {...{ signUp, host }} useV2Layout />
        </AccountsPageContents>
    );
};

export default Page;
