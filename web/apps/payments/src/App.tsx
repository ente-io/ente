import React, { useEffect, useRef, useState } from "react";
import { Container } from "./components/Container";
import { parseAndHandleRequest } from "./services/billing-service";
import S from "./utils/strings";

export const App: React.FC = () => {
    const [failed, setFailed] = useState(false);
    const once = useRef(false);

    useEffect(() => {
        if (once.current) return;
        once.current = true;
        parseAndHandleRequest().catch(() => {
            setFailed(true);
        });
    }, []);

    return <Container>{failed ? S.error_generic : <Spinner />}</Container>;
};

const Spinner: React.FC = () => <div className="loading-spinner"></div>;
