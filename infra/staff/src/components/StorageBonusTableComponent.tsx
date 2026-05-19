import {
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
} from "@mui/material";
import React, { useEffect, useState } from "react";
import { useInitialStaffSession } from "../services/session";
import { getCurrentAdminUser } from "../services/support";
import { StatusBadge } from "./StatusBadge";

interface BonusData {
    storage: number;
    type: string;
    createdAt: number;
    validTill: number;
    isRevoked: boolean;
}

export const StorageBonusTableComponent: React.FC = () => {
    const [storageBonuses, setStorageBonuses] = useState<BonusData[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const session = useInitialStaffSession();

    useEffect(() => {
        const fetchData = async () => {
            try {
                const userData = await getCurrentAdminUser<{
                    details?: { bonusData?: { storageBonuses?: BonusData[] } };
                }>(session);
                const bonuses: BonusData[] =
                    userData.details?.bonusData?.storageBonuses ?? [];
                setStorageBonuses(bonuses);
            } catch (error) {
                console.error("Error fetching bonus data:", error);
                setError("No bonus data");
            } finally {
                setLoading(false);
            }
        };

        fetchData().catch((error: unknown) =>
            console.error("Fetch data error:", error),
        );
    }, [session]);

    if (loading) {
        return <p>Loading...</p>;
    }

    if (error) {
        return <p>Error: {error}</p>;
    }

    if (storageBonuses.length === 0) {
        return <p>No bonus data available</p>;
    }

    return (
        <TableContainer
            component={Paper}
            sx={{ mt: "20px", mb: "20px", bgcolor: "#F1F1F3" }}
        >
            <Table aria-label="storage-bonus-table">
                <TableHead>
                    <TableRow>
                        <TableCell>
                            <b>Storage</b>
                        </TableCell>
                        <TableCell>
                            <b>Type</b>
                        </TableCell>
                        <TableCell>
                            <b>Created At</b>
                        </TableCell>
                        <TableCell>
                            <b>Valid Till</b>
                        </TableCell>
                        <TableCell>
                            <b>Is Revoked</b>
                        </TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {storageBonuses.map((bonus, index) => (
                        <TableRow key={index}>
                            <TableCell>
                                {formatStorage(bonus.storage)}
                            </TableCell>
                            <TableCell>{bonus.type}</TableCell>
                            <TableCell>
                                {formatCreatedAt(bonus.createdAt)}
                            </TableCell>
                            <TableCell>
                                {formatValidTill(bonus.validTill)}
                            </TableCell>
                            <TableCell>
                                <StatusBadge highlighted={bonus.isRevoked}>
                                    {bonus.isRevoked ? "Yes" : "No"}
                                </StatusBadge>
                            </TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>
        </TableContainer>
    );
};

const formatCreatedAt = (createdAt: number): string =>
    new Date(createdAt / 1000).toLocaleDateString();

const formatValidTill = (validTill: number): string => {
    if (validTill === 0) {
        return "Forever";
    }
    return new Date(validTill / 1000).toLocaleDateString();
};

const formatStorage = (storage: number): string =>
    `${(storage / 1024 ** 3).toFixed(2)} GB`;
