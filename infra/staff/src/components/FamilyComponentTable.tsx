import {
    Button,
    CircularProgress,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
} from "@mui/material";
import * as React from "react";
import { useEffect, useState } from "react";
import { getEmail, getToken } from "../App";
import { apiOrigin } from "../services/support";
import type { FamilyMember, UserData } from "../types";
import { formatUsageToGB } from "../utils/";
import CloseFamily from "./CloseFamily";

const FamilyTableComponent: React.FC = () => {
    const [familyMembers, setFamilyMembers] = useState<FamilyMember[]>([]);
    const [closeFamilyOpen, setCloseFamilyOpen] = useState(false);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

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
                    throw new Error("Network response was not ok");
                }
                const userData = (await response.json()) as UserData; // Typecast to UserData interface
                const members: FamilyMember[] =
                    userData.details?.familyData.members ?? [];
                setFamilyMembers(members);
            } catch (error) {
                console.error("Error fetching family data:", error);
                setError("No family data");
            } finally {
                setLoading(false);
            }
        };

        fetchData().catch((error: unknown) =>
            console.error("Fetch data error:", error),
        );
    }, []);

    const handleOpenCloseFamily = () => {
        setCloseFamilyOpen(true);
    };

    const handleCloseCloseFamily = () => {
        setCloseFamilyOpen(false);
    };

    const handleCloseFamily = () => {
        console.log("Close family action");
        handleOpenCloseFamily();
    };

    if (loading) {
        return <CircularProgress />;
    }

    if (error) {
        return <div>Error: {error}</div>;
    }

    if (familyMembers.length === 0) {
        return <div>No family data available</div>;
    }

    return (
        <>
            <TableContainer
                component={Paper}
                style={{
                    marginTop: "20px",
                    backgroundColor: "#F1F1F3",
                }}
            >
                <Table aria-label="family-table">
                    <TableHead>
                        <TableRow>
                            <TableCell>
                                <b>ID</b>
                            </TableCell>
                            <TableCell>
                                <b>User</b>
                            </TableCell>
                            <TableCell>
                                <b>Status</b>
                            </TableCell>
                            <TableCell>
                                <b>Usage</b>
                            </TableCell>
                            <TableCell>
                                <b>Quota</b>
                            </TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {familyMembers.map((member) => (
                            <TableRow key={member.id}>
                                <TableCell>{member.id}</TableCell>
                                <TableCell>{member.email}</TableCell>
                                <TableCell>
                                    <span
                                        style={{
                                            backgroundColor:
                                                member.status === "SELF"
                                                    ? "#00B33C"
                                                    : "transparent",
                                            color:
                                                member.status === "SELF"
                                                    ? "white"
                                                    : "inherit",
                                            padding: "4px 8px",
                                            borderRadius: "10px",
                                        }}
                                    >
                                        {member.status === "SELF"
                                            ? "ADMIN"
                                            : member.status}
                                    </span>
                                </TableCell>
                                <TableCell>
                                    {formatUsageToGB(member.usage)}
                                </TableCell>
                                <TableCell>
                                    {member.status !== "SELF"
                                        ? (member.storageLimit &&
                                              formatUsageToGB(
                                                  member.storageLimit,
                                              )) ||
                                          "NA"
                                        : ""}
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </TableContainer>
            <div style={{ marginTop: "20px" }}>
                <Button
                    variant="contained"
                    color="error"
                    onClick={handleCloseFamily}
                >
                    Close Family
                </Button>
            </div>

            {closeFamilyOpen && (
                <CloseFamily
                    open={closeFamilyOpen}
                    handleClose={handleCloseCloseFamily}
                    handleCloseFamily={handleCloseCloseFamily}
                />
            )}
        </>
    );
};

export default FamilyTableComponent;
