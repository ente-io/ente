import {
    Box,
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
import React, { useEffect, useState } from "react";
import { getCurrentAdminUser } from "../services/support";
import { CloseFamily } from "./CloseFamily";

interface FamilyMember {
    id: string;
    email: string;
    status: string;
    usage: number;
    storageLimit: number;
}

export const FamilyTableComponent: React.FC = () => {
    const [familyMembers, setFamilyMembers] = useState<FamilyMember[]>([]);
    const [closeFamilyOpen, setCloseFamilyOpen] = useState(false);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const userData = await getCurrentAdminUser<{
                    details?: { familyData?: { members?: FamilyMember[] } };
                }>();
                const members: FamilyMember[] =
                    userData.details?.familyData?.members ?? [];
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
                sx={{ mt: "20px", bgcolor: "#F1F1F3" }}
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
            <Box sx={{ mt: "20px" }}>
                <Button
                    variant="contained"
                    color="error"
                    onClick={handleOpenCloseFamily}
                >
                    Close Family
                </Button>
            </Box>

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

const formatUsageToGB = (usage: number): string =>
    `${(usage / (1024 * 1024 * 1024)).toFixed(2)} GB`;
