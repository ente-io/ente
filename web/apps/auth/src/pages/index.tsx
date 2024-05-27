import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();
    useEffect(() => {
        router.push(PAGES.LOGIN);
    }, []);

    return <></>;
};

export default Page;
