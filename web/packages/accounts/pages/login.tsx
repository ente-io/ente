import { AccountsPageContents } from "ente-accounts/components/layouts/centered-paper";
import { LoginContents } from "ente-accounts/components/LoginContents";
import { getData } from "ente-accounts/services/accounts-db";
import { LoadingIndicator } from "ente-base/components/loaders";
import { customAPIHost } from "ente-base/origins";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";

const Page: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>();

    const router = useRouter();

    useEffect(() => {
        void customAPIHost().then(setHost);
        const user = getData("user");
        if (user?.email) {
            void router.push("/verify");
        }
        setLoading(false);
    }, [router]);

    const onSignUp = () => void router.push("/signup");

    return loading ? (
        <LoadingIndicator />
    ) : (
        <AccountsPageContents>
            <LoginContents {...{ onSignUp, host }} />
        </AccountsPageContents>
    );
};

export default Page;
