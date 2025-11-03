import { useRouter } from "next/router";
import React, { useEffect } from "react";
import { FileShareView } from "../components/file-share/FileShareView";

const Page: React.FC = () => {
    const router = useRouter();
    const { t } = router.query;

    useEffect(() => {
        // Redirect to ente.io/locker if no token parameter
        if (router.isReady && !t) {
            window.location.href = "https://ente.io/locker";
        }
    }, [router.isReady, t]);

    // Don't render anything if redirecting
    if (!t) {
        return null;
    }

    return <FileShareView />;
};

export default Page;
