import Button from "@mui/material/Button";
import TextField from "@mui/material/TextField";
import React, { useEffect, useState } from "react";
import "./App.css";
import { apiOrigin } from "./services/support";
import duckieimage from "./components/duckie.png";
type User = Record<
    string,
    string | number | boolean | null | undefined | Record<string, unknown>
>;
type UserData = Record<string, User>;

export const App: React.FC = () => {
    const [token, setToken] = useState<string>("");
    const [email, setEmail] = useState<string>("");

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
        } catch (error) {
            console.error("Error fetching data:", error);
        }
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
            <form className="input-form" onKeyPress={handleKeyPress}>
                <div className="horizontal-group">
                    <a
                        href="https://staff.ente.sh"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="link-text"
                    >
                        staff.ente.sh
                    </a>

                    <TextField
                        label="Token"
                        value={token}
                        onChange={(e) => setToken(e.target.value)}
                        size="medium"
                        className="text-field-token" // Use CSS class for styles
                        style={{ width: "350px" }} // Adjust width as needed
                    />
                    <TextField
                        label="Email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        size="medium"
                        className="text-field-email" // Use CSS class for styles
                        style={{ width: "350px" }} // Adjust width as needed
                    />
                    <div className="fetch-button-container">
                        <Button
                            variant="contained"
                            onClick={() => {
                                fetchData().catch((error: unknown) =>
                                    console.error("Fetch data error:", error),
                                );
                            }}
                            className="fetch-button" // Use CSS class for styles
                            style={{
                                padding: "0 16px", // Add padding for better appearance
                            }}
                        >
                            FETCH
                        </Button>
                    </div>
                </div>
            </form>
            <div className="duckie-container">
                    <img src={duckieimage} alt="Duckie" className="duckie-image" />
                </div>
        </div>
    );
};

export default App;
