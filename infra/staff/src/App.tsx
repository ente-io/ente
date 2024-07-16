import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import Tab from "@mui/material/Tab";
import Tabs from "@mui/material/Tabs";
import TextField from "@mui/material/TextField";
import * as React from "react";
import { useEffect, useState } from "react";
import "./App.css";
import type { UserData } from "./components/UserComponent";
import UserComponent from "./components/UserComponent";
import duckieimage from "./components/duckie.png";
import { apiOrigin } from "./services/support";

// Define and export email and token variables and their setter functions
export let email = "";
export let token = "";

export const setEmail = (newEmail: string) => {
    email = newEmail;
};

export const setToken = (newToken: string) => {
    token = newToken;
};

export const getEmail = () => email;
export const getToken = () => token;

interface User {
    ID: string;
    email: string;
    creationTime: number;
}

interface Subscription {
    productID: string;
    paymentProvider: string;
    expiryTime: number;
    storage: number;
}

interface Security {
    isEmailMFAEnabled: boolean;
    isTwoFactorEnabled: boolean;
    passkeys: string; // Replace with actual passkey value if available
}

interface UserResponse {
    user: User;
    subscription: Subscription;
    details?: {
        usage?: number;
        storageBonus?: number;
        profileData: Security;
    };
}

const App: React.FC = () => {
    const [localEmail, setLocalEmail] = useState<string>(getEmail());
    const [localToken, setLocalToken] = useState<string>(getToken());
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>("");
    const [fetchSuccess, setFetchSuccess] = useState<boolean>(false);
    const [tabValue, setTabValue] = useState<number>(0);
    const [userData, setUserData] = useState<UserData | null>(null);

    useEffect(() => {
        const storedToken = localStorage.getItem("token");
        if (storedToken) {
            setToken(storedToken);
            setLocalToken(storedToken);
        }
    }, []);

    useEffect(() => {
        if (localToken) {
            setToken(localToken);
            localStorage.setItem("token", localToken);
        } else {
            localStorage.removeItem("token");
        }
    }, [localToken]);

    useEffect(() => {
        if (localEmail) {
            setEmail(localEmail);
            localStorage.setItem("email", localEmail);
        } else {
            localStorage.removeItem("email");
        }
    }, [localEmail]);

    const fetchData = async () => {
        setLoading(true);
        setError("");
        setFetchSuccess(false);
        const startTime = Date.now();
        try {
            const encodedEmail = encodeURIComponent(localEmail);
            const encodedToken = encodeURIComponent(localToken);
            const url = `${apiOrigin}/admin/user?email=${encodedEmail}&token=${encodedToken}`;
            console.log(`Fetching data from URL: ${url}`);
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const userDataResponse: UserResponse =
                (await response.json()) as UserResponse;
            console.log("API Response:", userDataResponse);

            const extractedUserData: UserData = {
                User: {
                    "User ID": userDataResponse.user.ID || "None",
                    Email: userDataResponse.user.email || "None",
                    "Creation time":
                        new Date(
                            userDataResponse.user.creationTime / 1000,
                        ).toLocaleString() || "None",
                },
                Storage: {
                    Total: userDataResponse.subscription.storage
                        ? userDataResponse.subscription.storage >= 1024 ** 3
                            ? `${(userDataResponse.subscription.storage / 1024 ** 3).toFixed(2)} GB`
                            : `${(userDataResponse.subscription.storage / 1024 ** 2).toFixed(2)} MB`
                        : "None",
                    Consumed:
                        userDataResponse.details?.usage !== undefined
                            ? userDataResponse.details.usage >= 1024 ** 3
                                ? `${(userDataResponse.details.usage / 1024 ** 3).toFixed(2)} GB`
                                : `${(userDataResponse.details.usage / 1024 ** 2).toFixed(2)} MB`
                            : "None",
                    Bonus:
                        userDataResponse.details?.storageBonus !== undefined
                            ? userDataResponse.details.storageBonus >= 1024 ** 3
                                ? `${(userDataResponse.details.storageBonus / 1024 ** 3).toFixed(2)} GB`
                                : `${(userDataResponse.details.storageBonus / 1024 ** 2).toFixed(2)} MB`
                            : "None",
                },
                Subscription: {
                    "Product ID":
                        userDataResponse.subscription.productID || "None",
                    Provider:
                        userDataResponse.subscription.paymentProvider || "None",
                    "Expiry time":
                        new Date(
                            userDataResponse.subscription.expiryTime / 1000,
                        ).toLocaleString() || "None",
                },
                Security: {
                    "Email MFA": userDataResponse.details?.profileData
                        .isEmailMFAEnabled
                        ? "Enabled"
                        : "Disabled",
                    "Two factor 2FA": userDataResponse.details?.profileData
                        .isTwoFactorEnabled
                        ? "Enabled"
                        : "Disabled",
                    Passkeys: "None", // Replace with actual passkey value if available
                },
            };

            const elapsedTime = Date.now() - startTime;
            const delay = Math.max(3000 - elapsedTime, 0);
            setTimeout(() => {
                setLoading(false);
                setFetchSuccess(true);
                setUserData(extractedUserData);
            }, delay);
        } catch (error) {
            console.error("Error fetching data:", error);
            const elapsedTime = Date.now() - startTime;
            const delay = Math.max(3000 - elapsedTime, 0);
            setTimeout(() => {
                setLoading(false);
                setError("Invalid token or email id");
            }, delay);
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

    const handleTabChange = (
        _event: React.SyntheticEvent,
        newValue: number,
    ) => {
        setTabValue(newValue);
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
                        value={localToken}
                        onChange={(e) => {
                            setLocalToken(e.target.value);
                            setToken(e.target.value);
                        }}
                        size="medium"
                        className="text-field-token"
                        style={{ width: "350px" }}
                    />
                    <TextField
                        label="Email"
                        value={localEmail}
                        onChange={(e) => {
                            setLocalEmail(e.target.value);
                            setEmail(e.target.value);
                        }}
                        size="medium"
                        className="text-field-email"
                        style={{ width: "350px" }}
                    />
                    <div className="fetch-button-container">
                        <Button
                            variant="contained"
                            onClick={() => {
                                fetchData().catch((error: unknown) =>
                                    console.error("Fetch data error:", error),
                                );
                            }}
                            className="fetch-button"
                            style={{
                                padding: "0 16px",
                            }}
                        >
                            FETCH
                        </Button>
                    </div>
                </div>
            </form>
            <div className="content-container">
                {loading ? (
                    <CircularProgress sx={{ color: "black" }} />
                ) : error ? (
                    <div className="error-message">{error}</div>
                ) : fetchSuccess ? (
                    <>
                        <Box
                            sx={{
                                width: "100%",
                                maxWidth: "600px",
                                bgcolor: "#FAFAFA",
                                marginTop: "300px",
                                borderRadius: "7px",
                                position: "relative",
                                zIndex: 1000,
                            }}
                        >
                            <Tabs
                                value={tabValue}
                                onChange={handleTabChange}
                                centered
                                sx={{
                                    "& .MuiTabs-indicator": {
                                        backgroundColor: "#00B33C",
                                        height: "5px",
                                        borderRadius: "20px",
                                    },
                                    "& .MuiTab-root": {
                                        textTransform: "none",
                                    },
                                    "& .Mui-selected": {
                                        color: "black !important",
                                    },
                                    "& .MuiTab-root.Mui-selected": {
                                        color: "black !important",
                                    },
                                }}
                            >
                                <Tab label="User" />
                                <Tab label="Family" />
                                <Tab label="Bonuses" />
                            </Tabs>
                        </Box>
                        <Box
                            sx={{
                                width: "100%",
                                maxWidth: "600px",
                                mt: 4,
                                minHeight: "400px",
                            }}
                        >
                            {tabValue === 0 && (
                                <UserComponent userData={userData} />
                            )}
                            {tabValue === 1 && <div>Family tab content</div>}
                            {tabValue === 2 && <div>Bonuses tab content</div>}
                        </Box>
                    </>
                ) : (
                    <div className="duckie-container">
                        <img
                            src={duckieimage}
                            alt="Duckie"
                            className="duckie-image"
                        />
                    </div>
                )}
            </div>
        </div>
    );
};

export default App;
