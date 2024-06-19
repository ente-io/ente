import React, { useState } from "react";
import "../App.css";
import { apiOrigin } from "../services/support";

interface SidebarProps {
    token: string;
    email: string;
}

interface UserData {
    user: {
        ID: string;
    };
}

export const Sidebar: React.FC<SidebarProps> = ({ token, email }) => {
    const [, /*userId*/ setUserId] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [message, setMessage] = useState<string | null>(null);
    const [dropdownVisible, setDropdownVisible] = useState<boolean>(false);

    interface ApiResponse {
        data: {
            userId: string;
        };
    }

    const fetchData = async (): Promise<string | null> => {
        if (!email || !token) {
            setError("Email or token is missing.");
            return null;
        }

        try {
            const url = `${apiOrigin}/admin/user?email=${encodeURIComponent(
                email,
            )}&token=${encodeURIComponent(token)}`;
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const userDataResponse = (await response.json()) as UserData;
            const fetchedUserId = userDataResponse.user.ID;
            if (!fetchedUserId) {
                throw new Error("User ID not found in response");
            }
            setUserId(fetchedUserId);
            setError(null);
            return fetchedUserId;
        } catch (error) {
            console.error("Error fetching data:", error);
            setError(
                error instanceof Error && typeof error.message === "string"
                    ? error.message
                    : "An unexpected error occurred",
            );

            setTimeout(() => {
                setError(null);
            }, 1000);
            return null;
        }
    };

    const performAction = async (userId: string, action: string) => {
        try {
            const actionUrls: Record<string, string> = {
                Disable2FA: "/admin/user/disable-2fa",
                DisablePasskeys: "/admin/user/disable-passkeys",
                Closefamily: "/admin/user/close-family",
            };

            const url = `${apiOrigin}${actionUrls[action]}?id=${encodeURIComponent(
                userId,
            )}&token=${encodeURIComponent(token)}`;
            const response = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ userId }),
            });

            if (!response.ok) {
                throw new Error(
                    `Network response was not ok: ${response.status}`,
                );
            }

            const result = (await response.json()) as ApiResponse;
            console.log("API Response:", result);

            setMessage(`${action} completed successfully`);
            setError(null);
            setTimeout(() => {
                setMessage(null);
            }, 1000);
            setDropdownVisible(false);
        } catch (error) {
            console.error(`Error ${action}:`, error);
            setError(
                error instanceof Error && typeof error.message === "string"
                    ? error.message
                    : "An unexpected error occurred",
            );

            setTimeout(() => {
                setError(null);
            }, 1000);
            setMessage(null);
        }
    };

    const handleActionClick = async (action: string) => {
        try {
            const fetchedUserId = await fetchData();
            if (!fetchedUserId) {
                throw new Error("Incorrect email id or token");
            }

            await performAction(fetchedUserId, action);
        } catch (error) {
            console.error(`Error performing ${action}:`, error);
            setError(
                error instanceof Error && typeof error.message === "string"
                    ? error.message
                    : "An unexpected error occurred",
            );

            setTimeout(() => {
                setError(null);
            }, 1000);
            setMessage(null);
        }
    };

    const toggleDropdown = () => {
        setDropdownVisible(!dropdownVisible);
    };

    const dropdownOptions = [
        { value: "Disable2FA", label: "Disable 2FA" },
        { value: "Closefamily", label: "Close Family" },
        { value: "DisablePasskeys", label: "Disable Passkeys" },
    ];

    return (
        <div className="sidebar">
            <div className="dropdown-container">
                <button className="more-button" onClick={toggleDropdown}>
                    MORE
                </button>
                {dropdownVisible && (
                    <div className="dropdown-menu">
                        <ul>
                            {dropdownOptions.map((option) => (
                                <li key={option.value}>
                                    <button
                                        onClick={() => {
                                            handleActionClick(
                                                option.value,
                                            ).catch((error: unknown) =>
                                                console.error(
                                                    "Error handling action:",
                                                    error,
                                                ),
                                            );
                                        }}
                                    >
                                        {option.label}
                                    </button>
                                </li>
                            ))}
                        </ul>
                    </div>
                )}
            </div>
            {(error ?? message) && (
                <div className={`message ${error ? "error" : "success"}`}>
                    {error ? `Error: ${error}` : `Success: ${message}`}
                </div>
            )}
        </div>
    );
};

export default Sidebar;
