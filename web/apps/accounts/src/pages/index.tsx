import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        router.push("/login");
    }, []);

    return <></>;
};

export default Page;
