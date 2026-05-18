import {
    Box,
    Button,
    CircularProgress,
    Tab,
    Tabs,
    TextField,
} from "@mui/material";
import React, { useCallback, useEffect, useState } from "react";
import "./App.css";
import { FamilyTableComponent } from "./components/FamilyComponentTable";
import { StorageBonusTableComponent } from "./components/StorageBonusTableComponent";
import { TokensTableComponent } from "./components/TokenTableComponent";
import { UserComponent, type UserData } from "./components/UserComponent";
import duckieimage from "./components/duckie.png";
import { getEmail, getToken, setEmail, setToken } from "./services/session";
import { apiOrigin } from "./services/support";

interface UserResponse {
    user: { ID: string; email: string; creationTime: number };
    subscription: {
        productID: string;
        paymentProvider: string;
        expiryTime: number;
        storage: number;
    };
    authCodes?: number;
    details?: {
        usage?: number;
        storageBonus?: number;
        profileData: {
            isEmailMFAEnabled: boolean;
            isTwoFactorEnabled: boolean;
            passkeyCount: number;
            canDisableEmailMFA: boolean;
        };
    };
}

export const App: React.FC = () => {
    const [localEmail, setLocalEmail] = useState("");
    const [localToken, setLocalToken] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [fetchSuccess, setFetchSuccess] = useState(false);
    const [tabValue, setTabValue] = useState(0);
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

    const fetchData = useCallback(
        async (input?: string, authToken?: string) => {
            setLoading(true);
            setError("");
            setFetchSuccess(false);
            const startTime = Date.now();
            try {
                const userSearchInput = (input ?? getEmail()).trim();
                const url = buildUserSearchUrl(userSearchInput);
                const response = await fetch(url, {
                    headers: {
                        "Content-Type": "application/json",
                        "X-AUTH-TOKEN": authToken ?? getToken(),
                    },
                });
                if (!response.ok) {
                    throw new Error("Network response was not ok");
                }
                const userDataResponse: UserResponse =
                    (await response.json()) as UserResponse;
                setEmail(userDataResponse.user.email || userSearchInput);

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
                        Total: formatStorage(
                            userDataResponse.subscription.storage,
                            true,
                        ),
                        Consumed: formatStorage(
                            userDataResponse.details?.usage,
                        ),
                        Bonus: formatStorage(
                            userDataResponse.details?.storageBonus,
                        ),
                    },
                    subscription: {
                        "Product ID":
                            userDataResponse.subscription.productID || "None",
                        Provider:
                            userDataResponse.subscription.paymentProvider ||
                            "None",
                        "Expiry time":
                            new Date(
                                userDataResponse.subscription.expiryTime / 1000,
                            ).toISOString() || "None",
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
                            (userDataResponse.details?.profileData
                                .passkeyCount ?? 0) > 0
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
                    setError("Invalid token or email/user id");
                }, delay);
            }
        },
        [],
    );

    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const urlEmail = urlParams.get("email");
        const urlToken = urlParams.get("token");

        if (urlEmail) {
            setLocalEmail(urlEmail);
            setEmail(urlEmail);
        }
        if (urlToken) {
            setLocalToken(urlToken);
            setToken(urlToken);
        }
        if (urlEmail && urlToken) {
            fetchData(urlEmail, urlToken).catch((error: unknown) =>
                console.error("Fetch data error:", error),
            );
        }
    }, [fetchData]);

    const handleKeyDown = (event: React.KeyboardEvent<HTMLFormElement>) => {
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
        <div className="container">
            <form className="input-form" onKeyDown={handleKeyDown}>
                <div className="horizontal-group">
                    <a
                        href="https://staff.ente.sh"
                        target="_blank"
                        rel="noopener"
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
                        />
                    </div>
                    <div className="fetch-button-container">
                        <Button
                            variant="contained"
                            onClick={() => {
                                fetchData().catch((error: unknown) =>
                                    console.error("Fetch data error:", error),
                                );
                            }}
                            style={{ padding: "0 16px" }}
                        >
                            FETCH
                        </Button>
                    </div>
                </div>
            </form>
            <div className="content-container">
                {loading ? (
                    <CircularProgress
                        sx={{ color: "black", top: "200px", position: "fixed" }}
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
                                    "& .MuiTab-root": { textTransform: "none" },
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
                                <FamilyTableComponent />
                            )}
                            {tabValue === 2 && userData && (
                                <StorageBonusTableComponent />
                            )}
                            {tabValue === 3 && userData && (
                                <TokensTableComponent />
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

const buildUserSearchUrl = (input: string): string => {
    const trimmedInput = input.trim();
    if (isNumericUserId(trimmedInput)) {
        return `${apiOrigin}/admin/user?id=${encodeURIComponent(trimmedInput)}`;
    }
    return `${apiOrigin}/admin/user?email=${encodeURIComponent(trimmedInput)}`;
};

const isNumericUserId = (value: string): boolean => /^\d+$/.test(value);

const formatStorage = (bytes: number | undefined, noneWhenZero = false) => {
    if (bytes === undefined || (noneWhenZero && bytes === 0)) {
        return "None";
    }
    if (bytes >= 1024 ** 3) {
        return `${(bytes / 1024 ** 3).toFixed(2)} GB`;
    }
    return `${(bytes / 1024 ** 2).toFixed(2)} MB`;
};
