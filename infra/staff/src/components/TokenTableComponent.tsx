import {
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TableSortLabel,
} from "@mui/material";
import * as React from "react";
import { useEffect, useState } from "react";
import { getEmail, getToken } from "../App";
import { apiOrigin } from "../services/support";

interface TokenData {
    creationTime: number;
    lastUsedTime: number;
    ua: string;
    isDeleted: boolean;
    app: string;
}

interface UserData {
    tokens: TokenData[];
}

const TokensTableComponent: React.FC = () => {
    const [tokens, setTokens] = useState<TokenData[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [order, setOrder] = useState<"asc" | "desc">("asc");
    const [orderBy, setOrderBy] = useState<keyof TokenData>("lastUsedTime");

    useEffect(() => {
        const fetchData = async () => {
            try {
                const encodedEmail = encodeURIComponent(getEmail());
                const token = getToken();
                const url = `${apiOrigin}/admin/user?email=${encodedEmail}`;
                const response = await fetch(url, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "X-Auth-Token": token,
                    },
                });
                if (!response.ok) {
                    throw new Error("Failed to fetch token data");
                }
                const userData = (await response.json()) as UserData;
                setTokens(userData.tokens);
            } catch (error) {
                console.error("Error fetching token data:", error);
                setError("No token data");
            } finally {
                setLoading(false);
            }
        };

        fetchData().catch((error: unknown) =>
            console.error("Fetch data error:", error),
        );
    }, []);

    const handleRequestSort = (property: keyof TokenData) => {
        const isAsc = orderBy === property && order === "asc";
        setOrder(isAsc ? "desc" : "asc");
        setOrderBy(property);
    };

    const sortedTokens = tokens.sort((a, b) => {
        if (orderBy === "lastUsedTime" || orderBy === "creationTime") {
            return order === "asc"
                ? a[orderBy] - b[orderBy]
                : b[orderBy] - a[orderBy];
        }
        return 0;
    });

    const formatDate = (timestamp: number): string => {
        const date = new Date(timestamp / 1000);
        return date.toLocaleDateString();
    };

    if (loading) {
        return <p>Loading...</p>;
    }

    if (error) {
        return <p>Error: {error}</p>;
    }

    if (tokens.length === 0) {
        return <p>No token data available</p>;
    }

    return (
        <div style={{ marginTop: "20px", marginBottom: "20px" }}>
            <TableContainer
                component={Paper}
                style={{
                    backgroundColor: "#F1F1F3",
                }}
            >
                <Table aria-label="tokens-table">
                    <TableHead>
                        <TableRow>
                            <TableCell
                                sortDirection={
                                    orderBy === "creationTime" ? order : false
                                }
                            >
                                <TableSortLabel
                                    active={orderBy === "creationTime"}
                                    direction={
                                        orderBy === "creationTime"
                                            ? order
                                            : "asc"
                                    }
                                    onClick={() =>
                                        handleRequestSort("creationTime")
                                    }
                                >
                                    Created At
                                </TableSortLabel>
                            </TableCell>
                            <TableCell
                                sortDirection={
                                    orderBy === "lastUsedTime" ? order : false
                                }
                            >
                                <TableSortLabel
                                    active={orderBy === "lastUsedTime"}
                                    direction={
                                        orderBy === "lastUsedTime"
                                            ? order
                                            : "asc"
                                    }
                                    onClick={() =>
                                        handleRequestSort("lastUsedTime")
                                    }
                                >
                                    Last Used At
                                </TableSortLabel>
                            </TableCell>
                            <TableCell>
                                <b>User Agent</b>
                            </TableCell>
                            <TableCell>
                                <b>App</b>
                            </TableCell>
                            <TableCell>
                                <b>Is Deleted</b>
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {sortedTokens.map((token, index) => (
                            <TableRow key={index}>
                                <TableCell>
                                    {formatDate(token.creationTime)}
                                </TableCell>
                                <TableCell>
                                    {formatDate(token.lastUsedTime)}
                                </TableCell>
                                <TableCell>{token.ua}</TableCell>
                                <TableCell>{token.app}</TableCell>
                                <TableCell>
                                    <span
                                        style={{
                                            backgroundColor: token.isDeleted
                                                ? "#494949"
                                                : "transparent",
                                            color: token.isDeleted
                                                ? "white"
                                                : "inherit",
                                            padding: "4px 8px",
                                            borderRadius: "10px",
                                        }}
                                    >
                                        {token.isDeleted ? "Yes" : "No"}
                                    </span>
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </TableContainer>
        </div>
    );
};

export default TokensTableComponent;
