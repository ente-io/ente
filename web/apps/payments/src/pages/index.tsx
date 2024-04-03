import { Container } from "components/Container";
import { Spinner } from "components/Spinner";
import React, { useEffect } from "react";
import { parseAndHandleRequest } from "services/billing-service";
import S from "utils/strings";

const Page: React.FC = () => {
    const [failed, setFailed] = React.useState(false);

    useEffect(() => {
        parseAndHandleRequest().catch(() => {
            setFailed(true);
        });
    }, []);

    return <Container>{failed ? S.error_generic : <Spinner />}</Container>;
};

export default Page;
