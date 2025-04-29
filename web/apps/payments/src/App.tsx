import React, { useEffect, useRef, useState } from "react";
import { parseAndHandleRequest } from "./services/billing";
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

const Container: React.FC<React.PropsWithChildren> = ({ children }) => (
    <div className="container">{children}</div>
);

const Spinner: React.FC = () => <div className="loading-spinner"></div>;
