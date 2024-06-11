import React, { useEffect, useState } from "react";
import { apiOrigin } from "./services/support";
import S from "./utils/strings";

export const App: React.FC = () => {
    const [token, setToken] = useState("");
    const [email, setEmail] = useState("");
    const [userData, setUserData] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);

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
            const url = `${apiOrigin}/admin/user?email=${email}&token=${token}`;
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const userData = await response.json();
            console.log("API Response:", userData);
            setUserData(userData);
            setError(null);
        } catch (error) {
            console.error("Error fetching data:", error);
            setError((error as Error).message);
        }
    };

    const renderAttributes = (data: any) => {
        if (!data) return null;

        let nullAttributes: string[] = [];

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
                        {renderAttributes(value)}
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
                        const parsedValue = JSON.parse(value);
                        displayValue = parsedValue;
                    } catch (error) {
                        displayValue = value;
                    }
                } else if (value === null) {
                    displayValue = "null";
                } else if (typeof value !== "undefined") {
                    displayValue = value.toString();
                } else {
                    displayValue = "undefined";
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

    return (
        <div className="container center-table">
            <h1>{S.hello}</h1>

            <form className="input-form">
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
            <div className="fetch-button">
                <button
                    onClick={fetchData}
                    style={{
                        padding: "10px 20px",
                        fontSize: "16px",
                        cursor: "pointer",
                        backgroundColor: "#009879",
                        color: "white",
                        border: "none",
                        borderRadius: "5px",
                    }}
                >
                    FETCH
                </button>
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
                                {renderAttributes(userData[category])}
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
