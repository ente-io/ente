import React, { useEffect } from "react";

const Page: React.FC = () => {
    useEffect(() => {
        // There are no user navigable pages currently on accounts.ente.io.
        window.location.href = "https://web.ente.io";
    }, []);

    return <></>;
};

export default Page;
