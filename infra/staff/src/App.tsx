import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import Tab from "@mui/material/Tab";
import Tabs from "@mui/material/Tabs";
import TextField from "@mui/material/TextField";
import * as React from "react";
import { useEffect, useState } from "react";
import "./App.css";
import FamilyTableComponent from "./components/FamilyComponentTable";
import StorageBonusTableComponent from "./components/StorageBonusTableComponent";
import TokensTableComponent from "./components/TokenTableComponent";
import UserComponent from "./components/UserComponent";
import duckieimage from "./components/duckie.png";
import { apiOrigin } from "./services/support";
import type { UserData, UserResponse } from "./types";

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

const App: React.FC = () => {
    const [localEmail, setLocalEmail] = useState<string>("");
    const [localToken, setLocalToken] = useState<string>("");
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

    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const urlEmail = urlParams.get("email");
        const urlToken = urlParams.get("token");

        if (urlEmail && urlToken) {
            setLocalEmail(urlEmail);
            setLocalToken(urlToken);
            console.log(localEmail);
            console.log(localToken);
            setEmail(urlEmail);
            setToken(urlToken);
            fetchData().catch((error: unknown) =>
                console.error("Fetch data error:", error),
            );
        }
        console.log(email);
        console.log(token);
    }, []);

    const fetchData = async () => {
        setLoading(true);
        setError("");
        setFetchSuccess(false);
        const startTime = Date.now();
        try {
            const encodedEmail = encodeURIComponent(email);

            const url = `${apiOrigin}/admin/user?email=${encodedEmail}`;
            const response = await fetch(url, {
                headers: {
                    "Content-Type": "application/json",
                    "X-AUTH-TOKEN": token,
                },
            });
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const userDataResponse: UserResponse =
                (await response.json()) as UserResponse;
            console.log("API Response:", userDataResponse);

            const extractedUserData: UserData = {
                user: {
                    "User ID": userDataResponse.user.ID || "None",
                    Email: userDataResponse.user.email || "None",
                    "Creation time":
                        new Date(
                            userDataResponse.user.creationTime / 1000,
                        ).toLocaleString() || "None",
                },
                storage: {
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
                subscription: {
                    "Product ID":
                        userDataResponse.subscription.productID || "None",
                    Provider:
                        userDataResponse.subscription.paymentProvider || "None",
                    "Expiry time":
                        new Date(
                            userDataResponse.subscription.expiryTime / 1000,
                        ).toLocaleString() || "None",
                },
                security: {
                    "Email MFA": userDataResponse.details?.profileData
                        .isEmailMFAEnabled
                        ? "Enabled"
                        : "Disabled",
                    "Two factor 2FA": userDataResponse.details?.profileData
                        .isTwoFactorEnabled
                        ? "Enabled"
                        : "Disabled",
                    Passkeys:
                        (userDataResponse.details?.profileData.passkeyCount ??
                            0) > 0
                            ? "Enabled"
                            : "Disabled",
                    "Can Disable EmailMFA": userDataResponse.details
                        ?.profileData.canDisableEmailMFA
                        ? "Yes"
                        : "No",
                    AuthCodes: `${userDataResponse.authCodes ?? 0}`,
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
    useEffect(() => {
        const searchParam = new URLSearchParams(window.location.search);
        const userToken = searchParam.get("token");

        if (userToken) {
            setLocalToken(userToken);
            setToken(userToken);
        }
    }, []);

    return (
        <div className="container">
            <div>
                <form className="input-form" onKeyPress={handleKeyPress}>
                    <div className="horizontal-group">
                        <a
                            href="https://staff.ente.sh"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="link-text"
                        >
                            staff.ente.io
                        </a>
                        <div className="text-fields">
                            <TextField
                                label="Email"
                                value={localEmail}
                                onChange={(e) => {
                                    setLocalEmail(e.target.value);
                                    setEmail(e.target.value);
                                }}
                                size="medium"
                                className="text-field-email"
                                style={{ width: "parent" }}
                            />
                        </div>
                        <div className="fetch-button-container">
                            <Button
                                variant="contained"
                                onClick={() => {
                                    fetchData().catch((error: unknown) =>
                                        console.error(
                                            "Fetch data error:",
                                            error,
                                        ),
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
            </div>
            <div className="content-container">
                {loading ? (
                    <CircularProgress
                        sx={{
                            color: "black",
                            top: "200px",
                            position: "fixed",
                        }}
                    />
                ) : error ? (
                    <div className="error-message">{error}</div>
                ) : fetchSuccess ? (
                    <>
                        <Box
                            sx={{
                                width: "100%",
                                maxWidth: "600px",
                                bgcolor: "#FAFAFA",
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
                                }}
                            >
                                <Tab label="User" />
                                <Tab label="Family" />
                                <Tab label="Bonuses" />
                                <Tab label="Devices" />
                            </Tabs>
                        </Box>
                        <Box
                            sx={{
                                width: "100%",
                                maxWidth: "900px",
                                bgcolor: "#FAFAFA",
                                borderRadius: "7px",
                                padding: "20px",
                                position: "relative",
                                zIndex: 999,
                                marginTop: "16px",
                            }}
                        >
                            {tabValue === 0 && userData && (
                                <UserComponent userData={userData} />
                            )}
                            {tabValue === 1 && userData && (
                                <div>
                                    <FamilyTableComponent />
                                </div>
                            )}
                            {tabValue === 2 && userData && (
                                <div>
                                    <StorageBonusTableComponent />
                                </div>
                            )}
                            {tabValue === 3 && userData && (
                                <div>
                                    <TokensTableComponent />
                                </div>
                            )}
                        </Box>
                    </>
                ) : (
                    <img
                        src={duckieimage}
                        alt="duckie"
                        style={{ marginTop: "150px" }}
                    />
                )}
            </div>
        </div>
    );
};

export default App;
