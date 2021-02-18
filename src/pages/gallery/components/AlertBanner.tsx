import React from 'react';
import { Alert } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export default function AlertBanner({ bannerErrorCode }) {
    let errorMessage;
    switch (bannerErrorCode) {
        case 402:
            errorMessage = constants.SUBSCRIPTION_EXPIRED;
            break;
        case 426:
            errorMessage = constants.STORAGE_QUOTA_EXCEEDED;
        default:
            errorMessage = `Unknown Error Code - ${bannerErrorCode} Encountered`;
    }
    return (
        <Alert
            variant={'danger'}
            style={{ display: bannerErrorCode ? 'block' : 'none' }}
        >
            {errorMessage}
        </Alert>
    );
}
