import React from 'react';
import { Typography } from '@mui/material';
import { CenteredRow } from 'ente-base/components/containers';
import { TranslucentLoadingOverlay } from 'ente-base/components/loaders';
import { t } from 'i18next';

/**
 * Message shown during first load to inform users about potential delays
 */
export const FirstLoadMessage: React.FC = () => (
    <CenteredRow>
        <Typography variant="small" sx={{ color: "text.muted" }}>
            {t("initial_load_delay_warning")}
        </Typography>
    </CenteredRow>
);

/**
 * Message shown when the app is offline
 */
export const OfflineMessage: React.FC = () => (
    <Typography
        variant="small"
        sx={{ bgcolor: "background.paper", p: 2, mb: 1, textAlign: "center" }}
    >
        {t("offline_message")}
    </Typography>
);

/**
 * Blocking overlay shown during certain operations
 */
export const BlockingLoadOverlay: React.FC<{ show: boolean }> = ({ show }) => 
    show ? <TranslucentLoadingOverlay /> : null;
