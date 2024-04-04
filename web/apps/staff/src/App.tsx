import React from "react";
import S from "./utils/strings";

export const App: React.FC = () => {
    return (
        <div>
            <h1>{S.hello}</h1>
            <a href="https://help.ente.io">help.ente.io</a>
        </div>
    );
};
