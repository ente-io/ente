import { useRouter } from "next/router";
import { useEffect } from "react";

/** Legacy alias, remove once mobile code is updated (it is still in beta). */
const Page = () => {
    const router = useRouter();

    useEffect(() => {
        router.push("/passkeys/verify");
    }, []);

    return <></>;
};

export default Page;
