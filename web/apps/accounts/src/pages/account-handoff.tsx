import { useEffect } from "react";

/** Legacy alias, remove once mobile code is updated (it is still in beta). */
const Page = () => {
    useEffect(() => {
        window.location.href = window.location.href.replace(
            "account-handoff",
            "passkeys",
        );
    }, []);

    return <></>;
};

export default Page;
