import React from "react";
import { Alert } from "react-bootstrap";
import constants from "utils/strings/constants";

export default function ErrorAlert({ errorCode }) {
    let errorMessage;
    switch (errorCode) {
        case 402:
            errorMessage = constants.SUBSCRIPTION_EXPIRED;
            break;
        case 426:
            errorMessage = constants.STORAGE_QUOTA_EXCEEDED;
        default:
            errorMessage = errorCode;
    }
    console.log(errorCode);
    return (
        <Alert variant={'danger'} style={{ display: errorCode ? 'block' : 'none' }}>
            {errorMessage}
        </Alert>
    )
}