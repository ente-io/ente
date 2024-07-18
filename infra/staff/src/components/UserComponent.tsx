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
import ChangeEmail from "./ChangeEmail";
import DeleteAccount from "./DeleteAccont";
import Disable2FA from "./Disable2FA";
import DisablePasskeys from "./DisablePasskeys";
import UpdateSubscription from "./UpdateSubscription";
export interface UserData {
    User: Record<string, string>;
    Storage: Record<string, string>;
    Subscription: Record<string, string>;
    Security: Record<string, string>;
}

interface UserComponentProps {
    userData: UserData | null;
}

const UserComponent: React.FC<UserComponentProps> = ({ userData }) => {
    const [deleteAccountOpen, setDeleteAccountOpen] = React.useState(false);
    const [disable2FAOpen, setDisable2FAOpen] = React.useState(false);
    const [twoFactorEnabled, setTwoFactorEnabled] = React.useState(false);
    const [is2FADisabled, setIs2FADisabled] = React.useState(false);
    const [updateSubscriptionOpen, setUpdateSubscriptionOpen] =
        React.useState(false);
    const [changeEmailOpen, setChangeEmailOpen] = React.useState(false); // State for ChangeEmail dialog
    const [DisablePasskeysOpen, setDisablePasskeysOpen] = React.useState(false);

    React.useEffect(() => {
        if (userData?.Security["Two factor 2FA"] === "Enabled") {
            setTwoFactorEnabled(true);
        } else {
            setTwoFactorEnabled(false);
        }
    }, [userData]);

    const handleEditEmail = () => {
        console.log("Edit Email clicked");
        setChangeEmailOpen(true);
    };

    const handleCloseChangeEmail = () => {
        setChangeEmailOpen(false); // Close ChangeEmail dialog
    };

    const handleDeleteAccountClick = () => {
        setDeleteAccountOpen(true);
    };

    const handleCloseDeleteAccount = () => {
        setDeleteAccountOpen(false);
    };

    const handleOpenDisable2FA = () => {
        setDisable2FAOpen(true);
    };

    const handleCloseDisable2FA = () => {
        setDisable2FAOpen(false);
    };

    const handleDisable2FA = () => {
        setIs2FADisabled(true);
    };

    const handleCancelDisable2FA = () => {
        setTwoFactorEnabled(true);
        handleCloseDisable2FA();
    };

    const handleEditSubscription = () => {
        setUpdateSubscriptionOpen(true);
    };

    const handleCloseUpdateSubscription = () => {
        setUpdateSubscriptionOpen(false);
    };

    const handleOpenDisablePasskeys = () => {
        setDisablePasskeysOpen(true); // Open the CloseFamily dialog
    };

    const handleCloseDisablePasskeys = () => {
        setDisablePasskeysOpen(false); // Close the CloseFamily dialog
    };

    const handleDisablePasskeys = () => {
        // Implement your logic to close family here
        console.log("Close family action");
        handleOpenDisablePasskeys(); // Open CloseFamily dialog after closing family
    };

    if (!userData) {
        return null;
    }

    return (
        <Grid container spacing={6} justifyContent="center">
            {Object.entries(userData).map(([title, data]) => (
                <Grid item xs={12} sm={10} md={6} key={title}>
                    <TableContainer
                        component={Paper}
                        variant="outlined"
                        sx={{
                            backgroundColor: "#F1F1F3",
                            minHeight: 300,
                            display: "flex",
                            flexDirection: "column",
                            marginBottom: "20px",
                            height: "100%",
                            width: "100%",
                            padding: "13px",
                            "&:not(:last-child)": {
                                marginBottom: "40px",
                            },
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
                                {title}
                            </Typography>
                            {title === "User" && (
                                <IconButton
                                    edge="start"
                                    aria-label="delete"
                                    onClick={handleDeleteAccountClick}
                                >
                                    <DeleteIcon style={{ color: "" }} />
                                </IconButton>
                            )}
                            {title === "Subscription" && (
                                <IconButton
                                    edge="end"
                                    aria-label="edit"
                                    onClick={handleEditSubscription}
                                >
                                    <EditIcon style={{ color: "black" }} />
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
                                {Object.entries(
                                    data as Record<string, string>,
                                ).map(([label, value], index) => (
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
                                            {label === "Email" ? (
                                                <Box
                                                    sx={{
                                                        display: "flex",
                                                        alignItems: "center",
                                                        justifyContent:
                                                            "flex-end",
                                                    }}
                                                >
                                                    <Typography>
                                                        {value}
                                                    </Typography>
                                                    <IconButton
                                                        edge="end"
                                                        aria-label="edit-email"
                                                        onClick={
                                                            handleEditEmail
                                                        }
                                                    >
                                                        <EditIcon
                                                            style={{
                                                                color: "black",
                                                            }}
                                                        />
                                                    </IconButton>
                                                </Box>
                                            ) : label === "Passkeys" ? (
                                                <Button
                                                    variant="outlined"
                                                    onClick={
                                                        handleDisablePasskeys
                                                    }
                                                >
                                                    Disable Passkeys
                                                </Button>
                                            ) : typeof value === "string" ? (
                                                label === "Two factor 2FA" ? (
                                                    is2FADisabled ||
                                                    value === "Disabled" ? (
                                                        <Typography
                                                            sx={{
                                                                textAlign:
                                                                    "center",
                                                                width: "100%",
                                                                paddingLeft:
                                                                    "30px",
                                                            }}
                                                        >
                                                            {value}
                                                        </Typography>
                                                    ) : (
                                                        <Box
                                                            sx={{
                                                                display: "flex",
                                                                alignItems:
                                                                    "center",
                                                                justifyContent:
                                                                    "center",
                                                                width: "100%",
                                                            }}
                                                        >
                                                            <Typography>
                                                                {value}
                                                            </Typography>
                                                            {value ===
                                                                "Enabled" && (
                                                                <Switch
                                                                    checked={
                                                                        twoFactorEnabled
                                                                    }
                                                                    onChange={(
                                                                        e,
                                                                    ) => {
                                                                        const isChecked =
                                                                            e
                                                                                .target
                                                                                .checked;
                                                                        setTwoFactorEnabled(
                                                                            isChecked,
                                                                        );
                                                                        if (
                                                                            !isChecked
                                                                        ) {
                                                                            handleOpenDisable2FA();
                                                                        }
                                                                    }}
                                                                    sx={{
                                                                        "& .MuiSwitch-switchBase.Mui-checked":
                                                                            {
                                                                                color: "#00B33C",
                                                                                "&:hover":
                                                                                    {
                                                                                        backgroundColor:
                                                                                            "rgba(0, 179, 60, 0.08)",
                                                                                    },
                                                                            },
                                                                        "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track":
                                                                            {
                                                                                backgroundColor:
                                                                                    "#00B33C",
                                                                            },
                                                                    }}
                                                                />
                                                            )}
                                                        </Box>
                                                    )
                                                ) : (
                                                    <Typography>
                                                        {value}
                                                    </Typography>
                                                )
                                            ) : (
                                                <Typography>
                                                    {String(value)}
                                                </Typography>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                </Grid>
            ))}

            {/* Render DeleteAccount dialog */}
            <DeleteAccount
                open={deleteAccountOpen}
                handleClose={handleCloseDeleteAccount}
            />

            {/* Render Disable2FA dialog */}
            <Disable2FA
                open={disable2FAOpen}
                handleClose={handleCancelDisable2FA}
                handleDisable2FA={handleDisable2FA}
            />

            {/* Render UpdateSubscription dialog */}
            <UpdateSubscription
                open={updateSubscriptionOpen}
                onClose={handleCloseUpdateSubscription}
            />

            {/* Render ChangeEmail dialog */}
            <ChangeEmail
                open={changeEmailOpen}
                onClose={handleCloseChangeEmail}
            />

            {/* Render Passkeys Dialog */}
            <DisablePasskeys
                open={DisablePasskeysOpen}
                handleClose={handleCloseDisablePasskeys}
                handleDisablePasskeys={handleCloseDisablePasskeys}
            />
        </Grid>
    );
};

export default UserComponent;
