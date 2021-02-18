import React from 'react';
import { Alert } from 'react-bootstrap';
import {
    ERR_STORAGE_LIMIT_EXCEEDED,
    ERR_NO_ACTIVE_SUBSRICTION,
} from 'services/uploadService';
import constants from 'utils/strings/constants';
import { ERR_NO_INTERNET_CONNECTION } from './CreateCollection';

export default function AlertBanner({ bannerErrorCode }) {
    let errorMessage;
    switch (bannerErrorCode) {
        case ERR_NO_ACTIVE_SUBSRICTION:
            errorMessage = constants.SUBSCRIPTION_EXPIRED;
            break;
        case ERR_STORAGE_LIMIT_EXCEEDED:
            errorMessage = constants.STORAGE_QUOTA_EXCEEDED;
            break;
        case ERR_NO_INTERNET_CONNECTION:
            errorMessage = constants.NO_INTERNET_CONNECTION;
            break;
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
