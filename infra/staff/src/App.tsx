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
    const [urlCredentials] = useState(readUrlCredentials);
    const [localEmail, setLocalEmail] = useState(urlCredentials.email ?? "");
    const [localToken] = useState(
        () => urlCredentials.token ?? localStorage.getItem("token") ?? "",
    );
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [fetchSuccess, setFetchSuccess] = useState(false);
    const [tabValue, setTabValue] = useState(0);
    const [userData, setUserData] = useState<UserData | null>(null);

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
                        "X-Auth-Token": authToken ?? getToken(),
                    },
                });
                if (!response.ok) {
                    throw new Error("Network response was not ok");
                }
                const userDataResponse: UserResponse =
                    (await response.json()) as UserResponse;
                setEmail(userDataResponse.user.email || userSearchInput);
                const emailMFAEnabled =
                    userDataResponse.details?.profileData.isEmailMFAEnabled ??
                    false;
                const twoFactorEnabled =
                    userDataResponse.details?.profileData.isTwoFactorEnabled ??
                    false;
                const passkeysEnabled =
                    (userDataResponse.details?.profileData.passkeyCount ?? 0) >
                    0;
                const canDisableEmailMFA =
                    userDataResponse.details?.profileData.canDisableEmailMFA ??
                    false;

                const extractedUserData: UserData = {
                    email: userDataResponse.user.email || userSearchInput,
                    user: [
                        {
                            kind: "text",
                            label: "User ID",
                            value: userDataResponse.user.ID || "None",
                        },
                        {
                            kind: "email",
                            label: "Email",
                            value: userDataResponse.user.email || "None",
                        },
                        {
                            kind: "text",
                            label: "Creation time",
                            value:
                                new Date(
                                    userDataResponse.user.creationTime / 1000,
                                ).toLocaleString() || "None",
                        },
                    ],
                    storage: [
                        {
                            kind: "text",
                            label: "Total",
                            value: formatStorage(
                                userDataResponse.subscription.storage,
                                true,
                            ),
                        },
                        {
                            kind: "text",
                            label: "Consumed",
                            value: formatStorage(
                                userDataResponse.details?.usage,
                            ),
                        },
                        {
                            kind: "text",
                            label: "Bonus",
                            value: formatStorage(
                                userDataResponse.details?.storageBonus,
                            ),
                        },
                    ],
                    subscription: [
                        {
                            kind: "text",
                            label: "Product ID",
                            value:
                                userDataResponse.subscription.productID ||
                                "None",
                        },
                        {
                            kind: "text",
                            label: "Provider",
                            value:
                                userDataResponse.subscription.paymentProvider ||
                                "None",
                        },
                        {
                            kind: "expiry",
                            label: "Expiry time",
                            value:
                                new Date(
                                    userDataResponse.subscription.expiryTime /
                                        1000,
                                ).toISOString() || "None",
                        },
                    ],
                    security: [
                        {
                            kind: "emailMFA",
                            label: "Email MFA",
                            value: emailMFAEnabled ? "Enabled" : "Disabled",
                        },
                        {
                            kind: "twoFactor",
                            label: "Two factor 2FA",
                            value: twoFactorEnabled ? "Enabled" : "Disabled",
                        },
                        {
                            kind: "passkeys",
                            label: "Passkeys",
                            value: passkeysEnabled ? "Enabled" : "Disabled",
                        },
                        {
                            kind: "text",
                            label: "AuthCodes",
                            value: `${userDataResponse.authCodes ?? 0}`,
                        },
                    ],
                    securityState: {
                        emailMFAEnabled,
                        twoFactorEnabled,
                        canDisableEmailMFA,
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
        const { email, token } = urlCredentials;
        if (email && token) {
            queueMicrotask(() => {
                fetchData(email, token).catch((error: unknown) =>
                    console.error("Fetch data error:", error),
                );
            });
        }
    }, [fetchData, urlCredentials]);

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
                            sx={{ px: 2 }}
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
                        className="empty-state-image"
                    />
                )}
            </div>
        </div>
    );
};

const readUrlCredentials = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return { email: urlParams.get("email"), token: urlParams.get("token") };
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
