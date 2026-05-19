import {
    Box,
    Button,
    CircularProgress,
    Tab,
    Tabs,
    TextField,
} from "@mui/material";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import "./App.css";
import { FamilyTable } from "./components/FamilyTable";
import { StorageBonusTableComponent } from "./components/StorageBonusTableComponent";
import { TokensTableComponent } from "./components/TokenTableComponent";
import { UserDetails, type UserDetailsData } from "./components/UserDetails";
import duckieimage from "./components/duckie.png";
import { getUser, type UserResponse } from "./services/admin-user";
import { StaffSessionProvider } from "./services/session";

export const App: React.FC = () => {
    const [urlCredentials] = useState(readUrlCredentials);
    const [searchInput, setSearchInput] = useState(urlCredentials.email ?? "");
    const [authToken] = useState(
        () => urlCredentials.token ?? localStorage.getItem("token") ?? "",
    );
    const [selectedUserEmail, setSelectedUserEmail] = useState(
        urlCredentials.email ?? "",
    );
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [fetchSuccess, setFetchSuccess] = useState(false);
    const [tabValue, setTabValue] = useState(0);
    const [userData, setUserData] = useState<UserDetailsData | null>(null);

    useEffect(() => {
        if (authToken) {
            localStorage.setItem("token", authToken);
        } else {
            localStorage.removeItem("token");
        }
    }, [authToken]);

    const fetchData = useCallback(async (input: string, authToken: string) => {
        setLoading(true);
        setError("");
        setFetchSuccess(false);
        const startTime = Date.now();
        try {
            const userSearchInput = input.trim();
            const userDetailsData = buildUserDetailsData(
                await getUser({ token: authToken }, userSearchInput),
                userSearchInput,
            );
            setSelectedUserEmail(userDetailsData.email);
            const elapsedTime = Date.now() - startTime;
            const delay = Math.max(3000 - elapsedTime, 0);
            setTimeout(() => {
                setLoading(false);
                setFetchSuccess(true);
                setUserData(userDetailsData);
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
    }, []);

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
            fetchData(selectedUserEmail, authToken).catch((error: unknown) =>
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

    const session = useMemo(
        () => ({ email: selectedUserEmail, token: authToken }),
        [authToken, selectedUserEmail],
    );

    return (
        <StaffSessionProvider session={session}>
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
                                value={searchInput}
                                onChange={(e) => {
                                    const email = e.target.value;
                                    setSearchInput(email);
                                    setSelectedUserEmail(email);
                                }}
                                size="medium"
                            />
                        </div>
                        <div className="fetch-button-container">
                            <Button
                                variant="contained"
                                onClick={() => {
                                    fetchData(
                                        selectedUserEmail,
                                        authToken,
                                    ).catch((error: unknown) =>
                                        console.error(
                                            "Fetch data error:",
                                            error,
                                        ),
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
                                    <UserDetails userData={userData} />
                                )}
                                {tabValue === 1 && userData && <FamilyTable />}
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
        </StaffSessionProvider>
    );
};

const readUrlCredentials = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return { email: urlParams.get("email"), token: urlParams.get("token") };
};

const buildUserDetailsData = (
    userResponse: UserResponse,
    userSearchInput: string,
): UserDetailsData => {
    if (!userResponse.subscription) {
        throw new Error("Subscription data not found");
    }

    const { subscription } = userResponse;
    const emailMFAEnabled =
        userResponse.details?.profileData?.isEmailMFAEnabled ?? false;
    const twoFactorEnabled =
        userResponse.details?.profileData?.isTwoFactorEnabled ?? false;
    const passkeysEnabled =
        (userResponse.details?.profileData?.passkeyCount ?? 0) > 0;
    const canDisableEmailMFA =
        userResponse.details?.profileData?.canDisableEmailMFA ?? false;

    return {
        email: userResponse.user.email || userSearchInput,
        user: [
            {
                kind: "text",
                label: "User ID",
                value: userResponse.user.ID || "None",
            },
            {
                kind: "email",
                label: "Email",
                value: userResponse.user.email || "None",
            },
            {
                kind: "text",
                label: "Creation time",
                value:
                    new Date(
                        userResponse.user.creationTime / 1000,
                    ).toLocaleString() || "None",
            },
        ],
        storage: [
            {
                kind: "text",
                label: "Total",
                value: formatStorage(subscription.storage, true),
            },
            {
                kind: "text",
                label: "Consumed",
                value: formatStorage(userResponse.details?.usage),
            },
            {
                kind: "text",
                label: "Bonus",
                value: formatStorage(userResponse.details?.storageBonus),
            },
        ],
        subscription: [
            {
                kind: "text",
                label: "Product ID",
                value: subscription.productID || "None",
            },
            {
                kind: "text",
                label: "Provider",
                value: subscription.paymentProvider || "None",
            },
            {
                kind: "expiry",
                label: "Expiry time",
                value:
                    new Date(subscription.expiryTime / 1000).toISOString() ||
                    "None",
            },
        ],
        security: [
            { kind: "emailMFA", label: "Email MFA", enabled: emailMFAEnabled },
            {
                kind: "twoFactor",
                label: "Two factor 2FA",
                enabled: twoFactorEnabled,
            },
            { kind: "passkeys", label: "Passkeys", enabled: passkeysEnabled },
            {
                kind: "text",
                label: "AuthCodes",
                value: `${userResponse.authCodes ?? 0}`,
            },
        ],
        securityState: {
            emailMFAEnabled,
            twoFactorEnabled,
            canDisableEmailMFA,
        },
    };
};

const formatStorage = (bytes: number | undefined, noneWhenZero = false) => {
    if (bytes === undefined || (noneWhenZero && bytes === 0)) {
        return "None";
    }
    if (bytes >= 1024 ** 3) {
        return `${(bytes / 1024 ** 3).toFixed(2)} GB`;
    }
    return `${(bytes / 1024 ** 2).toFixed(2)} MB`;
};
