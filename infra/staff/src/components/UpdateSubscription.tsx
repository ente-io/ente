import React, { useEffect, useState } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import "../App.css";
import { apiOrigin } from "../services/support";
interface UpdateSubscriptionProps {
    token: string;
    userId: string;
    onClose: () => void;
}

export const UpdateSubscription: React.FC<UpdateSubscriptionProps> = ({
    token,
    userId,
    onClose,
}) => {
    const [expiryTime, setExpiryTime] = useState<Date | null>(null);
    const [productId, setProductId] = useState<string>("50gb_monthly");
    const [paymentProvider, setPaymentProvider] = useState<string>("bitpay");
    const [transactionId, setTransactionId] = useState<string>("");
    const [message, setMessage] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [storage, setStorage] = useState<number | "">("");

    useEffect(() => {
        if (productId === "50gb_yearly" || productId === "50gb_monthly") {
            setStorage(50 * 1024 * 1024 * 1024);
        } else if (
            productId === "200gb_yearly" ||
            productId === "200gb_monthly"
        ) {
            setStorage(200 * 1024 * 1024 * 1024);
        } else if (
            productId === "500gb_yearly" ||
            productId === "500gb_monthly"
        ) {
            setStorage(500 * 1024 * 1024 * 1024);
        } else if (
            productId === "2000gb_yearly" ||
            productId === "2000gb_monthly"
        ) {
            setStorage(2000 * 1024 * 1024 * 1024);
        } else {
            setStorage("");
        }
    }, [productId]);

    const handleSubmit = async (event: React.FormEvent) => {
        event.preventDefault();

        const expiryTimeTimestamp = expiryTime
            ? expiryTime.getTime() * 1000
            : "";

        const url = `${apiOrigin}/admin/user/subscription`;
        const body = {
            userId,
            storage,
            expiryTime: expiryTimeTimestamp,
            productId,
            paymentProvider,
            transactionId,
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
                throw new Error(
                    `Network response was not ok: ${response.status}`,
                );
            }

            setMessage("Subscription updated successfully");
            setError(null);
            setTimeout(() => {
                setMessage(null);
                onClose();
            }, 1000);
        } catch (error) {
            console.error("Error updating subscription:", error);
            setError(
                error instanceof Error && typeof error.message === "string"
                    ? error.message
                    : "An unexpected error occurred",
            );
            setTimeout(() => {
                setError(null);
            }, 1000);
        }
    };

    const handleSubmitWrapper = (event: React.FormEvent) => {
        handleSubmit(event).catch((error: unknown) => {
            console.error("Error in handleSubmit:", error);
        });
    };

    return (
        <div className="update-subscription-popup">
            <div className="popup-content">
                <button className="close-button" onClick={onClose}>
                    X
                </button>
                <h2>Update Subscription</h2>
                <form onSubmit={handleSubmitWrapper}>
                    <div className="form-group">
                        <label htmlFor="expiry-time">Expiry Time:</label>
                        <DatePicker
                            id="expiry-time"
                            selected={expiryTime}
                            onChange={(date) => setExpiryTime(date)}
                            dateFormat="dd/MM/yyyy"
                            showYearDropdown
                            scrollableYearDropdown
                            yearDropdownItemNumber={15}
                        />
                    </div>
                    <div className="form-group">
                        <label htmlFor="product-id">Choose Your Plan:</label>
                        <select
                            id="product-id"
                            value={productId}
                            onChange={(e) => setProductId(e.target.value)}
                        >
                            <option value="50gb_monthly">50GB/Month</option>
                            <option value="50gb_yearly">50GB/Year</option>
                            <option value="200gb_monthly">200GB/Month</option>
                            <option value="200gb_yearly">200GB/Year</option>
                            <option value="500gb_monthly">500GB/Month</option>
                            <option value="500gb_yearly">500GB/Year</option>
                            <option value="2000gb_monthly">2000GB/Month</option>
                            <option value="2000gb_yearly">2000GB/Year</option>
                        </select>
                    </div>
                    <div className="form-group">
                        <label htmlFor="payment-provider">
                            Payment Provider:
                        </label>
                        <select
                            id="payment-provider"
                            value={paymentProvider}
                            onChange={(e) => setPaymentProvider(e.target.value)}
                        >
                            <option value="bitpay">BitPay</option>
                            <option value="paypal">PayPal</option>
                        </select>
                    </div>
                    <div className="form-group">
                        <label htmlFor="transaction-id">Transaction ID:</label>
                        <input
                            id="transaction-id"
                            type="text"
                            value={transactionId}
                            onChange={(e) => setTransactionId(e.target.value)}
                        />
                    </div>
                    <button type="submit" id="submitbtn">
                        Update
                    </button>
                </form>
                {(error ?? message) && (
                    <div className={`message ${error ? "error" : "success"}`}>
                        {error ? `Error: ${error}` : `Success: ${message}`}
                    </div>
                )}
            </div>
        </div>
    );
};

export default UpdateSubscription;
