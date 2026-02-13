import { LoadingIndicator } from "ente-base/components/loaders";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        const shouldOpenLogin =
            typeof window !== "undefined" &&
            window.sessionStorage.getItem("ensu.openLogin") === "1";

        if (shouldOpenLogin) {
            window.sessionStorage.removeItem("ensu.openLogin");
            void router.replace("/login");
            return;
        }

        void router.replace("/chat");
    }, [router]);

    return <LoadingIndicator />;
};

export default Page;
