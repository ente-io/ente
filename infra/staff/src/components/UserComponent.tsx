import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid";
import IconButton from "@mui/material/IconButton";
import Paper from "@mui/material/Paper";
import Switch from "@mui/material/Switch";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableRow from "@mui/material/TableRow";
import Typography from "@mui/material/Typography";
import * as React from "react";
import type { UserComponentProps } from "../types";
import ChangeEmail from "./ChangeEmail";
import DeleteAccount from "./DeleteAccont";
import Disable2FA from "./Disable2FA";
import DisablePasskeys from "./DisablePasskeys";
import ToggleEmailMFA from "./ToggleEmailMFA";
import UpdateSubscription from "./UpdateSubscription";

const UserComponent: React.FC<UserComponentProps> = ({ userData }) => {
    const [deleteAccountOpen, setDeleteAccountOpen] = React.useState(false);
    const [email2FAEnabled, setEmail2FAEnabled] = React.useState(false);
    const [email2FAOpen, setEmail2FAToggleOpen] = React.useState(false);
    const [disable2FAOpen, setDisable2FAOpen] = React.useState(false);
    const [twoFactorEnabled, setTwoFactorEnabled] = React.useState(false);
    const [canDisableEmailMFA, setCanDisableEmailMFA] = React.useState(false);
    const [updateSubscriptionOpen, setUpdateSubscriptionOpen] =
        React.useState(false);
    const [changeEmailOpen, setChangeEmailOpen] = React.useState(false);
    const [disablePasskeysOpen, setDisablePasskeysOpen] = React.useState(false);

    React.useEffect(() => {
        setTwoFactorEnabled(userData?.security["Two factor 2FA"] === "Enabled");
        setEmail2FAEnabled(userData?.security["Email MFA"] === "Enabled");
        setCanDisableEmailMFA(
            userData?.security["Can Disable EmailMFA"] === "Yes",
        );
    }, [userData]);

    const handleEditEmail = () => setChangeEmailOpen(true);
    const handleDeleteAccountClick = () => setDeleteAccountOpen(true);
    const handleEditSubscription = () => setUpdateSubscriptionOpen(true);
    const handleDisablePasskeys = () => setDisablePasskeysOpen(true);

    if (!userData) return null;

    return (
        <Grid container spacing={6} justifyContent="center">
            {Object.entries(userData).map(([title, data]) => (
                <Grid item xs={12} sm={10} md={6} key={title}>
                    <DataTable
                        title={title}
                        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
                        data={data}
                        onEditEmail={handleEditEmail}
                        onDeleteAccount={handleDeleteAccountClick}
                        onEditSubscription={handleEditSubscription}
                        onDisablePasskeys={handleDisablePasskeys}
                        canDisableEmailMFA={canDisableEmailMFA}
                        twoFactorEnabled={twoFactorEnabled}
                        setTwoFactorEnabled={setTwoFactorEnabled}
                        setDisable2FAOpen={setDisable2FAOpen}
                        email2FAEnabled={email2FAEnabled}
                        setEmail2FAToggleOpen={setEmail2FAToggleOpen}
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
                handleToggleEmailMFA={(status) => setEmail2FAToggleOpen(status)}
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
        </Grid>
    );
};

interface DataTableProps {
    title: string;
    data: Record<string, string>;
    onEditEmail: () => void;
    onDeleteAccount: () => void;
    onEditSubscription: () => void;
    onDisablePasskeys: () => void;
    canDisableEmailMFA: boolean;
    twoFactorEnabled: boolean;
    setTwoFactorEnabled: (enabled: boolean) => void;
    setDisable2FAOpen: (open: boolean) => void;
    email2FAEnabled: boolean;
    setEmail2FAToggleOpen: (open: boolean) => void;
}

const DataTable: React.FC<DataTableProps> = ({
    title,
    data,
    onEditEmail,
    onDeleteAccount,
    onEditSubscription,
    onDisablePasskeys,
    canDisableEmailMFA,
    twoFactorEnabled,
    setTwoFactorEnabled,
    setDisable2FAOpen,
    email2FAEnabled,
    setEmail2FAToggleOpen,
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
                sx={{
                    fontWeight: "bold",
                    textAlign: "center",
                    width: "100%",
                }}
            >
                {title.charAt(0).toUpperCase() + title.slice(1)}
            </Typography>
            {title === "user" && (
                <IconButton
                    edge="start"
                    aria-label="delete"
                    onClick={onDeleteAccount}
                >
                    <DeleteIcon style={{ color: "" }} />
                </IconButton>
            )}
            {title === "subscription" && (
                <IconButton
                    edge="end"
                    aria-label="edit"
                    onClick={onEditSubscription}
                >
                    <EditIcon style={{ color: "black", marginRight: "15px" }} />
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
                {Object.entries(data)
                    .filter(([label]) => label !== "Can Disable EmailMFA")
                    .map(([label, value], index) => (
                        <TableRow key={label}>
                            <TableCell
                                component="th"
                                scope="row"
                                style={{
                                    padding: "16px",
                                    borderBottom:
                                        index === 1 || index === 0
                                            ? "1px solid rgba(224, 224, 224, 1)"
                                            : "none",
                                }}
                            >
                                {label}
                            </TableCell>
                            <TableCell
                                align="right"
                                style={{
                                    padding: "10px",
                                    borderBottom:
                                        index === 1 || index === 0
                                            ? "1px solid rgba(224, 224, 224, 1)"
                                            : "none",
                                }}
                            >
                                {/* eslint-disable-next-line @typescript-eslint/no-unsafe-assignment */}
                                {renderTableCellContent(
                                    label,
                                    value,
                                    onEditEmail,
                                    onDisablePasskeys,
                                    canDisableEmailMFA,
                                    twoFactorEnabled,
                                    setTwoFactorEnabled,
                                    setDisable2FAOpen,
                                    email2FAEnabled,
                                    setEmail2FAToggleOpen,
                                )}
                            </TableCell>
                        </TableRow>
                    ))}
            </TableBody>
        </Table>
    </TableContainer>
);

const renderTableCellContent = (
    label: string,
    value: string,
    onEditEmail: () => void,
    onDisablePasskeys: () => void,
    canToggleEmailMFA: boolean,
    twoFactorEnabled: boolean,
    setTwoFactorEnabled: (enabled: boolean) => void,
    setDisable2FAOpen: (open: boolean) => void,
    email2FAEnabled: boolean,
    setEmail2FAToggleOpen: (open: boolean) => void,
) => {
    switch (label) {
        case "Email":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "flex-end",
                    }}
                >
                    <Typography>{value}</Typography>
                    <IconButton
                        edge="end"
                        aria-label="edit-email"
                        onClick={onEditEmail}
                    >
                        <EditIcon style={{ color: "black" }} />
                    </IconButton>
                </Box>
            );
        case "Passkeys":
            return value === "Enabled" ? (
                <Button variant="outlined" onClick={onDisablePasskeys}>
                    Remove Passkey
                </Button>
            ) : (
                <Typography sx={{ width: "100%", paddingLeft: "1px" }}>
                    {value}
                </Typography>
            );
        case "Two factor 2FA":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "right",
                        width: "100%",
                        paddingRight: "50px",
                    }}
                >
                    <Typography sx={{ marginRight: "1px" }}>{value}</Typography>
                    {value === "Enabled" && (
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
                                    {
                                        backgroundColor: "#00B33C",
                                    },
                            }}
                        />
                    )}
                </Box>
            );
        // If Expirty time (in format 30/1/2026, 11:12:53 am) is greatheer than current date, show it in bold green
        case "Expiry time": {
            const expiryTime = new Date(
                Date.parse(
                    value.replace(
                        /(\d+)\/(\d+)\/(\d+), (\d+:\d+:\d+ \w+)/,
                        "$2/$1/$3 $4",
                    ),
                ),
            );
            const currentTime = new Date();
            return (
                <Typography
                    sx={{
                        color: expiryTime > currentTime ? "#00B33C" : "red",
                    }}
                >
                    {value}
                </Typography>
            );
        }
        case "Email MFA":
            return (
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "right",
                        width: "100%",
                        paddingRight: "50px",
                    }}
                >
                    <Typography sx={{ marginRight: "1px" }}>{value}</Typography>
                    {canToggleEmailMFA && (
                        <Switch
                            checked={email2FAEnabled}
                            // eslint-disable-next-line @typescript-eslint/no-unused-vars
                            onChange={(_) => {
                                setEmail2FAToggleOpen(true);
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
                                    {
                                        backgroundColor: "#00B33C",
                                    },
                            }}
                        />
                    )}
                </Box>
            );
        default:
            return <Typography>{value}</Typography>;
    }
};

export default UserComponent;
