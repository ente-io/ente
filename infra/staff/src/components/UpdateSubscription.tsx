import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import CloseIcon from "@mui/icons-material/Close";
import Button from "@mui/material/Button";
import Dialog from "@mui/material/Dialog";
import DialogActions from "@mui/material/DialogActions";
import DialogContent from "@mui/material/DialogContent";
import DialogTitle from "@mui/material/DialogTitle";
import Grid from "@mui/material/Grid";
import InputAdornment from "@mui/material/InputAdornment";
import MenuItem from "@mui/material/MenuItem";
import Select, { type SelectChangeEvent } from "@mui/material/Select";
import TextField from "@mui/material/TextField";
import React, { useEffect, useState } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { getEmail, getToken } from "../App";
import { apiOrigin } from "../services/support";
interface Subscription {
    productID: string;
    paymentProvider: string;
    storage: number;
    originalTransactionID: string;
    expiryTime: number;
    userID: string;
    attributes: {
        customerID: string;
        stripeAccountCountry: string;
    };
}

interface UserDataResponse {
    subscription: Subscription | null;
}

interface UpdateSubscriptionProps {
    open: boolean;
    onClose: () => void;
}

interface FormValues {
    productId: string;
    provider: string;
    storage: number;
    transactionId: string;
    expiryTime: string | Date | null;
    userId: string;
    attributes: {
        customerID: string;
        stripeAccountCountry: string;
    };
}

const UpdateSubscription: React.FC<UpdateSubscriptionProps> = ({
    open,
    onClose,
}) => {
    const [values, setValues] = useState<FormValues>({
        productId: "",
        provider: "",
        storage: 0,
        transactionId: "",
        expiryTime: "",
        userId: "",
        attributes: {
            customerID: "",
            stripeAccountCountry: "",
        },
    });

    const [isDatePickerOpen, setIsDatePickerOpen] = useState(false);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const email = getEmail();
                const token = getToken();
                const encodedEmail = encodeURIComponent(email);
                const url = `${apiOrigin}/admin/user?email=${encodedEmail}`;
                const response = await fetch(url, {
                    headers: {
                        "X-AUTH-TOKEN": token,
                    },
                });
                if (!response.ok) {
                    throw new Error("Network response was not ok");
                }
                const userDataResponse =
                    (await response.json()) as UserDataResponse;

                if (!userDataResponse.subscription) {
                    throw new Error("Subscription data not found");
                }

                const expiryTime = new Date(
                    userDataResponse.subscription.expiryTime / 1000,
                );

                setValues({
                    productId: userDataResponse.subscription.productID || "",
                    provider:
                        userDataResponse.subscription.paymentProvider || "",
                    storage:
                        userDataResponse.subscription.storage /
                            (1024 * 1024 * 1024) || 0,
                    transactionId:
                        userDataResponse.subscription.originalTransactionID ||
                        "",
                    expiryTime: expiryTime,
                    userId: userDataResponse.subscription.userID || "",
                    attributes: {
                        customerID:
                            userDataResponse.subscription.attributes
                                .customerID || "",
                        stripeAccountCountry:
                            userDataResponse.subscription.attributes
                                .stripeAccountCountry || "",
                    },
                });
            } catch (error) {
                console.error("Error fetching data:", error);
            }
        };

        fetchData().catch((error: unknown) => {
            console.error("Unhandled promise rejection:", error);
        });
    }, []);

    const handleCalendarClick = () => {
        setIsDatePickerOpen(true);
    };

    const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = event.target;
        setValues({
            ...values,
            [name]: name === "storage" ? parseInt(value, 10) : value,
        });
    };

    const handleChangeProvider = (event: SelectChangeEvent) => {
        const { name, value } = event.target;

        if (name) {
            setValues({
                ...values,
                [name]: value,
            });
        }
    };

    const handleDatePickerChange = (date: Date | null) => {
        setValues({
            ...values,
            expiryTime: date,
        });
        setIsDatePickerOpen(false);
    };

    const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        (async () => {
            const token = getToken();
            const url = `${apiOrigin}/admin/user/subscription`;

            let expiryTime = null;
            if (values.expiryTime instanceof Date) {
                const utcExpiryTime = new Date(values.expiryTime);
                expiryTime = utcExpiryTime.getTime() * 1000;
            }

            const body = {
                userId: values.userId,
                storage: values.storage * (1024 * 1024 * 1024),
                expiryTime: expiryTime,
                productId: values.productId,
                paymentProvider: values.provider,
                transactionId: values.transactionId,
                attributes: {
                    customerID: values.attributes.customerID,
                    stripeAccountCountry:
                        values.attributes.stripeAccountCountry,
                },
            };

            try {
                const response = await fetch(url, {
                    method: "PUT",
                    headers: {
                        "Content-Type": "application/json",
                        "X-AUTH-TOKEN": token,
                    },
                    body: JSON.stringify(body),
                });

                if (!response.ok) {
                    throw new Error("Network response was not ok");
                }
                console.log("Subscription updated successfully");
                onClose();
            } catch (error) {
                if (error instanceof Error) {
                    alert(`Failed to update subscription: ${error.message}`);
                } else {
                    alert("Failed to update subscription");
                }
            }
        })().catch((error: unknown) => {
            console.error("Unhandled promise rejection:", error);
        });
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            BackdropProps={{
                style: {
                    backdropFilter: "blur(5px)",
                    backgroundColor: "rgba(255, 255, 255, 0.8)",
                },
            }}
        >
            <DialogTitle style={{ marginBottom: "20px", marginTop: "20px" }}>
                Update Subscription
                <Button
                    onClick={onClose}
                    style={{ position: "absolute", right: 10, top: 10 }}
                >
                    <CloseIcon style={{ color: "black" }} />
                </Button>
            </DialogTitle>
            <DialogContent>
                <form onSubmit={handleSubmit}>
                    <Grid container spacing={4}>
                        <Grid item xs={6}>
                            <div style={{ marginBottom: "8px" }}>
                                <label
                                    htmlFor="productId"
                                    style={{
                                        textAlign: "left",
                                        display: "block",
                                        marginBottom: "4px",
                                    }}
                                >
                                    Product ID
                                </label>
                                <TextField
                                    id="productId"
                                    name="productId"
                                    value={values.productId}
                                    onChange={handleChange}
                                    fullWidth
                                />
                            </div>
                        </Grid>
                        <Grid item xs={6}>
                            <div style={{ marginBottom: "8px" }}>
                                <label
                                    htmlFor="provider"
                                    style={{
                                        textAlign: "left",
                                        display: "block",
                                        marginBottom: "4px",
                                    }}
                                >
                                    Provider
                                </label>
                                <Select
                                    id="provider"
                                    name="provider"
                                    value={values.provider}
                                    onChange={handleChangeProvider}
                                    fullWidth
                                    style={{ textAlign: "left" }}
                                >
                                    <MenuItem value="stripe">Stripe</MenuItem>
                                    <MenuItem value="paypal">PayPal</MenuItem>
                                    <MenuItem value="bitpay">BitPay</MenuItem>
                                    <MenuItem value="None">None</MenuItem>
                                </Select>
                            </div>
                        </Grid>
                        <Grid item xs={6}>
                            <div style={{ marginBottom: "8px" }}>
                                <label
                                    htmlFor="storage"
                                    style={{
                                        textAlign: "left",
                                        display: "block",
                                        marginBottom: "4px",
                                    }}
                                >
                                    Storage (GB)
                                </label>
                                <TextField
                                    id="storage"
                                    name="storage"
                                    type="number"
                                    value={values.storage}
                                    onChange={handleChange}
                                    fullWidth
                                />
                            </div>
                        </Grid>
                        <Grid item xs={6}>
                            <div style={{ marginBottom: "8px" }}>
                                <label
                                    htmlFor="transactionId"
                                    style={{
                                        textAlign: "left",
                                        display: "block",
                                        marginBottom: "4px",
                                    }}
                                >
                                    Transaction ID
                                </label>
                                <TextField
                                    id="transactionId"
                                    name="transactionId"
                                    value={values.transactionId}
                                    onChange={handleChange}
                                    fullWidth
                                />
                            </div>
                        </Grid>
                        <Grid item xs={6}>
                            <div style={{ marginBottom: "8px" }}>
                                <label
                                    htmlFor="expiryTime"
                                    style={{
                                        textAlign: "left",
                                        display: "block",
                                        marginBottom: "4px",
                                    }}
                                >
                                    Expiry Time
                                </label>
                                <TextField
                                    id="expiryTime"
                                    name="expiryTime"
                                    value={
                                        values.expiryTime instanceof Date
                                            ? values.expiryTime.toLocaleDateString(
                                                  "en-GB",
                                              )
                                            : ""
                                    }
                                    onClick={handleCalendarClick}
                                    InputProps={{
                                        endAdornment: (
                                            <InputAdornment position="end">
                                                <CalendarTodayIcon />
                                            </InputAdornment>
                                        ),
                                        readOnly: true,
                                    }}
                                    fullWidth
                                />
                                {isDatePickerOpen && (
                                    <DatePicker
                                        showYearDropdown
                                        scrollableYearDropdown
                                        yearDropdownItemNumber={100}
                                        selected={
                                            values.expiryTime instanceof Date
                                                ? values.expiryTime
                                                : null
                                        }
                                        onChange={handleDatePickerChange}
                                        onClickOutside={() =>
                                            setIsDatePickerOpen(false)
                                        }
                                        withPortal
                                        inline
                                    />
                                )}
                            </div>
                        </Grid>
                    </Grid>
                    <DialogActions style={{ justifyContent: "center" }}>
                        <Button
                            type="submit"
                            variant="contained"
                            style={{
                                backgroundColor: "#00B33C",
                                color: "white",
                            }}
                        >
                            Update
                        </Button>
                    </DialogActions>
                </form>
            </DialogContent>
        </Dialog>
    );
};

export default UpdateSubscription;
