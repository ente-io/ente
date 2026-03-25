import React, { useEffect } from "react";

const Page: React.FC = () => {
    useEffect(() => {
        // There are no user navigable pages currently on accounts.ente.com.
        window.location.href = "https://web.ente.com";
    }, []);

    return <></>;
};

export default Page;
