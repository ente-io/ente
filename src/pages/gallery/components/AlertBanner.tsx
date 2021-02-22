import React from 'react';
import { Alert } from 'react-bootstrap';

import { ErrorBannerMessage } from 'utils/common/errorUtil';

export default function AlertBanner({ bannerErrorCode }) {
    return (
        <Alert
            variant={'danger'}
            style={{ display: bannerErrorCode ? 'block' : 'none' }}
        >
            {ErrorBannerMessage(bannerErrorCode)}
        </Alert>
    );
}
