import React, { useEffect } from "react";

const Page: React.FC = () => {
    useEffect(() => {
        // There are no user navigable pages on the accounts app.
        window.location.href = "https://ente.com";
    }, []);

    return <></>;
};

export default Page;
