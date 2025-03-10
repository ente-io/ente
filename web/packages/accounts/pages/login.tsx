import { AccountsPageContents } from "@/accounts/components/layouts/centered-paper";
import { LoginContents } from "@/accounts/components/LoginContents";
import { PAGES } from "@/accounts/constants/pages";
import { LoadingIndicator } from "@/base/components/loaders";
import { customAPIHost } from "@/base/origins";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";

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
    }, [router]);

    const onSignUp = () => void router.push(PAGES.SIGNUP);

    return loading ? (
        <LoadingIndicator />
    ) : (
        <AccountsPageContents>
            <LoginContents {...{ onSignUp, host }} />
        </AccountsPageContents>
    );
};

export default Page;
