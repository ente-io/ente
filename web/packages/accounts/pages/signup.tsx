import { AccountsPageContents } from "@/accounts/components/layouts/centered-paper";
import { SignUpContents } from "@/accounts/components/SignUpContents";
import { LoadingIndicator } from "@/base/components/loaders";
import { customAPIHost } from "@/base/origins";
import { getData } from "@ente/shared//storage/localStorage";
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
