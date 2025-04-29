import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();
    useEffect(() => void router.push("/login"), [router]);
    return <></>;
};

export default Page;
