import React, { useEffect, useState } from "react";
import "./App.css";
import { Sidebar } from "./components/Sidebar";
import { apiOrigin } from "./services/support";
import S from "./utils/strings";

type User = Record<
    string,
    string | number | boolean | null | undefined | Record<string, unknown>
>;
type UserData = Record<string, User>;

export const App: React.FC = () => {
    const [token, setToken] = useState<string>("");
    const [email, setEmail] = useState<string>("");
    const [userData, setUserData] = useState<UserData | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [isDataFetched, setIsDataFetched] = useState<boolean>(false);

    useEffect(() => {
        const storedToken = localStorage.getItem("token");
        if (storedToken) {
            setToken(storedToken);
        }
    }, []);

    useEffect(() => {
        if (token) {
            localStorage.setItem("token", token);
        } else {
            localStorage.removeItem("token");
        }
    }, [token]);

    const fetchData = async () => {
        try {
            const encodedEmail = encodeURIComponent(email);
            const encodedToken = encodeURIComponent(token);
            const url = `${apiOrigin}/admin/user?email=${encodedEmail}&token=${encodedToken}`;
            console.log(`Fetching data from URL: ${url}`);
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const userDataResponse = (await response.json()) as UserData;
            console.log("API Response:", userDataResponse);
            setUserData(userDataResponse);
            setError(null);
            setIsDataFetched(true);
        } catch (error) {
            console.error("Error fetching data:", error);
            setError((error as Error).message);
            setIsDataFetched(false);
        }
    };

    const renderAttributes = (
        data: Record<string, unknown> | User | null,
    ): React.ReactNode => {
        if (!data) return null;

        const nullAttributes: string[] = [];

        const rows = Object.entries(data).map(([key, value]) => {
            console.log("Processing key:", key, "value:", value);

            if (
                typeof value === "object" &&
                value !== null &&
                !Array.isArray(value)
            ) {
                return (
                    <React.Fragment key={key}>
                        <tr>
                            <td
                                colSpan={2}
                                style={{
                                    fontWeight: "bold",
                                    backgroundColor: "#f1f1f1",
                                    padding: "10px",
                                }}
                            >
                                {key.toUpperCase()}
                            </td>
                        </tr>
                        {renderAttributes(
                            value as Record<string, unknown> | User,
                        )}
                    </React.Fragment>
                );
            } else {
                if (value === null) {
                    nullAttributes.push(key);
                }

                let displayValue: React.ReactNode;
                if (key === "expiryTime" && typeof value === "number") {
                    displayValue = new Date(value / 1000).toLocaleString();
                } else if (
                    key === "creationTime" &&
                    typeof value === "number"
                ) {
                    displayValue = new Date(value / 1000).toLocaleString();
                } else if (key === "storage" && typeof value === "number") {
                    displayValue = `${(value / 1024 ** 3).toFixed(2)} GB`;
                } else if (typeof value === "string") {
                    try {
                        const parsedValue = JSON.parse(
                            value,
                        ) as React.ReactNode;
                        displayValue = parsedValue;
                    } catch (error) {
                        displayValue = value;
                    }
                } else if (typeof value === "object" && value !== null) {
                    displayValue = JSON.stringify(value, null, 2);
                } else if (value === null) {
                    displayValue = "null";
                } else if (
                    typeof value === "boolean" ||
                    typeof value === "number"
                ) {
                    displayValue = value.toString();
                } else if (typeof value === "undefined") {
                    displayValue = "undefined";
                } else {
                    displayValue = value as string;
                }

                return (
                    <tr key={key}>
                        <td
                            style={{
                                padding: "10px",
                                border: "1px solid #ddd",
                            }}
                        >
                            {key}
                        </td>
                        <td
                            style={{
                                padding: "10px",
                                border: "1px solid #ddd",
                            }}
                        >
                            {displayValue}
                        </td>
                    </tr>
                );
            }
        });

        console.log("Attributes with null values:", nullAttributes);

        return rows;
    };

    const handleKeyPress = (event: React.KeyboardEvent<HTMLFormElement>) => {
        if (event.key === "Enter") {
            event.preventDefault();
            fetchData().catch((error: unknown) =>
                console.error("Fetch data error:", error),
            );
        }
    };

    return (
        <div className="container center-table">
            <h1>{S.hello}</h1>
            <form className="input-form" onKeyPress={handleKeyPress}>
                <div className="input-group">
                    <label>
                        Token:
                        <input
                            type="text"
                            value={token}
                            onChange={(e) => setToken(e.target.value)}
                            style={{
                                padding: "10px",
                                margin: "10px",
                                width: "100%",
                            }}
                        />
                    </label>
                </div>
                <div className="input-group">
                    <label>
                        Email id:
                        <input
                            type="text"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            style={{
                                padding: "10px",
                                margin: "10px",
                                width: "100%",
                            }}
                        />
                    </label>
                </div>
            </form>
            <div className="content-wrapper">
                {isDataFetched && <Sidebar token={token} email={email} />}
                <div className="fetch-button-container">
                    <button
                        onClick={() => {
                            fetchData().catch((error: unknown) =>
                                console.error("Fetch data error:", error),
                            );
                        }}
                    >
                        FETCH
                    </button>
                </div>
            </div>
            <br />
            {error && <p style={{ color: "red" }}>{`Error: ${error}`}</p>}
            {userData && (
                <table
                    style={{
                        width: "100%",
                        borderCollapse: "collapse",
                        margin: "20px 0",
                        fontSize: "1em",
                        minWidth: "400px",
                        boxShadow: "0 0 20px rgba(0, 0, 0, 0.15)",
                    }}
                >
                    <tbody>
                        {Object.keys(userData).map((category) => (
                            <React.Fragment key={category}>
                                <tr>
                                    <td
                                        colSpan={2}
                                        style={{
                                            fontWeight: "bold",
                                            backgroundColor: "#f1f1f1",
                                            padding: "10px",
                                        }}
                                    >
                                        {category.toUpperCase()}
                                    </td>
                                </tr>
                                {renderAttributes(userData[category] ?? null)}
                            </React.Fragment>
                        ))}
                    </tbody>
                </table>
            )}
            <footer className="footer">
                <p>
                    <a href="https://help.ente.io">help.ente.io</a>
                </p>
            </footer>
        </div>
    );
};

export default App;
