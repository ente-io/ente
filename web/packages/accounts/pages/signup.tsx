import { AccountsPageContents } from "ente-accounts/components/layouts/centered-paper";
import { SignUpContents } from "ente-accounts/components/SignUpContents";
import { getData } from "ente-accounts/services/accounts-db";
import { LoadingIndicator } from "ente-base/components/loaders";
import { customAPIHost } from "ente-base/origins";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";

/**
 * A page that allows the user to signup for a new Ente account.
 */
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

    const onLogin = () => void router.push("/login");

    return loading ? (
        <LoadingIndicator />
    ) : (
        <AccountsPageContents>
            <SignUpContents {...{ onLogin, router, host }} />
        </AccountsPageContents>
    );
};

export default Page;
