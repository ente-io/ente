import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useRouter } from "next/router";
import { useEffect } from "react";

const IndexPage = () => {
    const router = useRouter();
    useEffect(() => {
        router.push(PAGES.LOGIN);
    }, []);

    return <></>;
};

export default IndexPage;
