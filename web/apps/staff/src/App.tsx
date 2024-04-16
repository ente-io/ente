import React from "react";
import { getUserDetails } from "./services/support-service";
import S from "./utils/strings";

export const App: React.FC = () => {
    const handleClick = () => {
        const authToken = "xxx";
        getUserDetails(authToken)
            .then((userDetails) => {
                console.log("Fetched user details", userDetails);
            })
            .catch((e) => {
                console.error("Failed to fetch user details", e);
            });
    };

    return (
        <div>
            <h1>{S.hello}</h1>
            <p>
                <a href="https://help.ente.io">help.ente.io</a>
            </p>
            <p>
                <button onClick={handleClick}>Do something</button>
            </p>
        </div>
    );
};
