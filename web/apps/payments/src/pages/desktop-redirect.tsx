import { Container } from "components/Container";
import { Spinner } from "components/Spinner";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    useEffect(() => {
        const currentURL = new URL(window.location.href);
        const desktopRedirectURL = new URL("ente://app/gallery");
        desktopRedirectURL.search = currentURL.search;
        window.location.href = desktopRedirectURL.href;
    }, []);

    return (
        <Container>
            <Spinner />
        </Container>
    );
};

export default Page;
