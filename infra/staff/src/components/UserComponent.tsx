import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import {
    Box,
    Button,
    Grid,
    IconButton,
    Paper,
    Switch,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableRow,
    Typography,
} from "@mui/material";
import React, { useEffect, useState } from "react";
import { AddOTT } from "./AddOTT";
import { ChangeEmail } from "./ChangeEmail";
import { DeleteAccount } from "./DeleteAccount";
import { Disable2FA } from "./Disable2FA";
import { DisablePasskeys } from "./DisablePasskeys";
import { ToggleEmailMFA } from "./ToggleEmailMFA";
import { UpdateSubscription } from "./UpdateSubscription";

export interface UserData {
    email: string;
    user: UserTableRow[];
    storage: UserTableRow[];
    subscription: UserTableRow[];
    security: UserTableRow[];
    securityState: {
        emailMFAEnabled: boolean;
        twoFactorEnabled: boolean;
        canDisableEmailMFA: boolean;
    };
}

type UserTableRow =
    | { kind: "text"; label: string; value: string }
    | { kind: "email"; label: string; value: string }
    | { kind: "expiry"; label: string; value: string }
    | { kind: "passkeys"; label: string; value: string }
    | { kind: "twoFactor"; label: string; value: string }
    | { kind: "emailMFA"; label: string; value: string };

type UserSectionKey = "user" | "storage" | "subscription" | "security";

interface UserComponentProps {
    userData: UserData;
}

export const UserComponent: React.FC<UserComponentProps> = ({ userData }) => {
    const [deleteAccountOpen, setDeleteAccountOpen] = useState(false);
    const [email2FAEnabled, setEmail2FAEnabled] = useState(
        userData.securityState.emailMFAEnabled,
    );
    const [email2FAOpen, setEmail2FAToggleOpen] = useState(false);
    const [disable2FAOpen, setDisable2FAOpen] = useState(false);
    const [twoFactorEnabled, setTwoFactorEnabled] = useState(
        userData.securityState.twoFactorEnabled,
    );
    const [updateSubscriptionOpen, setUpdateSubscriptionOpen] = useState(false);
    const [changeEmailOpen, setChangeEmailOpen] = useState(false);
    const [disablePasskeysOpen, setDisablePasskeysOpen] = useState(false);
    const [addOTTOpen, setAddOTTOpen] = useState(false);
    const { canDisableEmailMFA } = userData.securityState;

    useEffect(() => {
        // These switches are local after successful mutations, but same-user
        // refetches should still resync them with the server.
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setEmail2FAEnabled(userData.securityState.emailMFAEnabled);
        setTwoFactorEnabled(userData.securityState.twoFactorEnabled);
    }, [
        userData.securityState.emailMFAEnabled,
        userData.securityState.twoFactorEnabled,
    ]);

    const handleEditEmail = () => setChangeEmailOpen(true);
    const handleDeleteAccountClick = () => setDeleteAccountOpen(true);
    const handleEditSubscription = () => setUpdateSubscriptionOpen(true);
    const handleDisablePasskeys = () => setDisablePasskeysOpen(true);

    const sections: {
        key: UserSectionKey;
        title: string;
        rows: UserTableRow[];
    }[] = [
        { key: "user", title: "User", rows: userData.user },
        { key: "storage", title: "Storage", rows: userData.storage },
        {
            key: "subscription",
            title: "Subscription",
            rows: userData.subscription,
        },
        { key: "security", title: "Security", rows: userData.security },
    ];

    return (
        <Grid container spacing={6} sx={{ justifyContent: "center" }}>
            {sections.map(({ key, title, rows }) => (
                <Grid size={{ xs: 12, sm: 10, md: 6 }} key={key}>
                    <DataTable
                        sectionKey={key}
                        title={title}
                        rows={rows}
                        onEditEmail={handleEditEmail}
                        onDeleteAccount={handleDeleteAccountClick}
                        onEditSubscription={handleEditSubscription}
                        onDisablePasskeys={handleDisablePasskeys}
                        onAddOTT={() => setAddOTTOpen(true)}
                        canDisableEmailMFA={canDisableEmailMFA}
                        twoFactorEnabled={twoFactorEnabled}
                        setTwoFactorEnabled={setTwoFactorEnabled}
                        setDisable2FAOpen={setDisable2FAOpen}
                        email2FAEnabled={email2FAEnabled}
                        onToggleEmailMFA={() => setEmail2FAToggleOpen(true)}
                    />
                </Grid>
            ))}

            <DeleteAccount
                open={deleteAccountOpen}
                handleClose={() => setDeleteAccountOpen(false)}
            />
            <Disable2FA
                open={disable2FAOpen}
                handleClose={() => setDisable2FAOpen(false)}
                handleDisable2FA={() => setTwoFactorEnabled(false)}
            />
            <ToggleEmailMFA
                open={email2FAOpen}
                handleClose={() => setEmail2FAToggleOpen(false)}
                handleToggleEmailMFA={setEmail2FAEnabled}
            />
            <UpdateSubscription
                open={updateSubscriptionOpen}
                onClose={() => setUpdateSubscriptionOpen(false)}
            />
            <ChangeEmail
                open={changeEmailOpen}
                onClose={() => setChangeEmailOpen(false)}
            />
            <DisablePasskeys
                open={disablePasskeysOpen}
                handleClose={() => setDisablePasskeysOpen(false)}
                handleDisablePasskeys={() => setDisablePasskeysOpen(false)}
            />
            <AddOTT
                open={addOTTOpen}
                onClose={() => setAddOTTOpen(false)}
                userEmail={userData.email}
            />
        </Grid>
    );
};

interface DataTableProps {
    sectionKey: UserSectionKey;
    title: string;
    rows: UserTableRow[];
    onEditEmail: () => void;
    onDeleteAccount: () => void;
    onEditSubscription: () => void;
    onDisablePasskeys: () => void;
    onAddOTT: () => void;
    canDisableEmailMFA: boolean;
    twoFactorEnabled: boolean;
    setTwoFactorEnabled: (enabled: boolean) => void;
    setDisable2FAOpen: (open: boolean) => void;
    email2FAEnabled: boolean;
    onToggleEmailMFA: () => void;
}

const DataTable: React.FC<DataTableProps> = ({
    sectionKey,
    title,
    rows,
    onEditEmail,
    onDeleteAccount,
    onEditSubscription,
    onDisablePasskeys,
    onAddOTT,
    canDisableEmailMFA,
    twoFactorEnabled,
    setTwoFactorEnabled,
    setDisable2FAOpen,
    email2FAEnabled,
    onToggleEmailMFA,
}) => (
    <TableContainer
        component={Paper}
        variant="outlined"
        sx={{
            backgroundColor: "#F1F1F3",
            minHeight: 300,
            display: "flex",
            flexDirection: "column",
            height: "100%",
            width: "100%",
            padding: "10px",
            overflowX: "hidden",
        }}
    >
        <Box
            sx={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "16px",
                width: "100%",
            }}
        >
            <Typography
                variant="h6"
                component="div"
                sx={{ fontWeight: "bold", textAlign: "center", width: "100%" }}
            >
                {title}
            </Typography>
            {sectionKey === "user" && (
                <IconButton
                    edge="start"
                    aria-label="delete"
                    onClick={onDeleteAccount}
                >
                    <DeleteIcon />
                </IconButton>
            )}
            {sectionKey === "subscription" && (
                <IconButton
                    edge="end"
                    aria-label="edit"
                    onClick={onEditSubscription}
                >
                    <EditIcon sx={{ color: "black", mr: "15px" }} />
                </IconButton>
            )}
        </Box>

        <Table
            sx={{
                width: "100%",
                tableLayout: "fixed",
                height: "100%",
                borderBottom: "none",
            }}
            aria-label={title}
        >
            <TableBody>
                {rows.map((row, index) => (
                    <TableRow key={`${row.kind}:${row.label}`}>
                        <TableCell
                            component="th"
                            scope="row"
                            sx={{
                                p: "16px",
                                borderBottom:
                                    index === 1 || index === 0
                                        ? "1px solid rgba(224, 224, 224, 1)"
                                        : "none",
                            }}
                        >
                            {row.label}
                        </TableCell>
                        <TableCell
                            align="right"
                            sx={{
                                p: "10px",
                                borderBottom:
                                    index === 1 || index === 0
                                        ? "1px solid rgba(224, 224, 224, 1)"
                                        : "none",
                            }}
                        >
                            {renderTableCellContent(
                                row,
                                onEditEmail,
                                onDisablePasskeys,
                                canDisableEmailMFA,
                                twoFactorEnabled,
                                setTwoFactorEnabled,
                                setDisable2FAOpen,
                                email2FAEnabled,
                                onToggleEmailMFA,
                            )}
                        </TableCell>
                    </TableRow>
                ))}
                {sectionKey === "security" && (
                    <TableRow>
                        <TableCell
                            component="th"
                            scope="row"
                            sx={{ p: "16px", borderBottom: "none" }}
                        >
                            Add OTT
                        </TableCell>
                        <TableCell
                            align="right"
                            sx={{ p: "10px", borderBottom: "none" }}
                        >
                            <Button
                                variant="contained"
                                onClick={onAddOTT}
                                sx={{ textTransform: "none" }}
                            >
                                Add OTT
                            </Button>
                        </TableCell>
                    </TableRow>
                )}
            </TableBody>
        </Table>
    </TableContainer>
);

const renderTableCellContent = (
    row: UserTableRow,
    onEditEmail: () => void,
    onDisablePasskeys: () => void,
    canToggleEmailMFA: boolean,
    twoFactorEnabled: boolean,
    setTwoFactorEnabled: (enabled: boolean) => void,
    setDisable2FAOpen: (open: boolean) => void,
    email2FAEnabled: boolean,
    onToggleEmailMFA: () => void,
) => {
    switch (row.kind) {
        case "email":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "flex-end",
                    }}
                >
                    <Typography>{row.value}</Typography>
                    <IconButton
                        edge="end"
                        aria-label="edit-email"
                        onClick={onEditEmail}
                    >
                        <EditIcon sx={{ color: "black" }} />
                    </IconButton>
                </Box>
            );
        case "passkeys":
            return row.value === "Enabled" ? (
                <Button variant="outlined" onClick={onDisablePasskeys}>
                    Remove Passkey
                </Button>
            ) : (
                <Typography sx={{ width: "100%", paddingLeft: "1px" }}>
                    {row.value}
                </Typography>
            );
        case "twoFactor":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "flex-end",
                        width: "100%",
                        paddingRight: "50px",
                    }}
                >
                    <Typography sx={{ marginRight: "1px" }}>
                        {row.value}
                    </Typography>
                    {row.value === "Enabled" && (
                        <Switch
                            checked={twoFactorEnabled}
                            onChange={(e) => {
                                const isChecked = e.target.checked;
                                setTwoFactorEnabled(isChecked);
                                if (!isChecked) {
                                    setDisable2FAOpen(true);
                                }
                            }}
                            sx={{
                                "& .MuiSwitch-switchBase.Mui-checked": {
                                    color: "#00B33C",
                                    "&:hover": {
                                        backgroundColor:
                                            "rgba(0, 179, 60, 0.08)",
                                    },
                                },
                                "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track":
                                    { backgroundColor: "#00B33C" },
                            }}
                        />
                    )}
                </Box>
            );
        case "expiry": {
            const expiryTime = new Date(row.value);
            const currentTime = new Date();
            const isValidExpiryTime = !Number.isNaN(expiryTime.getTime());
            return (
                <Typography
                    sx={{
                        color:
                            isValidExpiryTime && expiryTime > currentTime
                                ? "#00B33C"
                                : "red",
                    }}
                >
                    {isValidExpiryTime
                        ? expiryTime.toLocaleString()
                        : row.value}
                </Typography>
            );
        }
        case "emailMFA":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "flex-end",
                        width: "100%",
                        paddingRight: "50px",
                    }}
                >
                    <Typography sx={{ marginRight: "1px" }}>
                        {row.value}
                    </Typography>
                    {canToggleEmailMFA && (
                        <Switch
                            checked={email2FAEnabled}
                            onChange={onToggleEmailMFA}
                            sx={{
                                "& .MuiSwitch-switchBase.Mui-checked": {
                                    color: "#00B33C",
                                    "&:hover": {
                                        backgroundColor:
                                            "rgba(0, 179, 60, 0.08)",
                                    },
                                },
                                "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track":
                                    { backgroundColor: "#00B33C" },
                            }}
                        />
                    )}
                </Box>
            );
        default:
            return <Typography>{row.value}</Typography>;
    }
};
