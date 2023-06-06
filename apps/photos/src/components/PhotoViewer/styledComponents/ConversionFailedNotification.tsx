import { useState } from 'react';
import Notification from 'components/Notification';
import React from 'react';
import { t } from 'i18next';

interface Iprops {
    onClick: () => void;
}

export const ConversionFailedNotification = ({ onClick }: Iprops) => {
    const [open, setOpen] = useState(true);
    const handleClose = () => {
        setOpen(false);
    };

    return (
        <Notification
            open={open}
            onClose={handleClose}
            attributes={{
                variant: 'secondary',
                message: t('CONVERSION_FAILED_NOTIFICATION_MESSAGE'),
                onClick: onClick,
            }}
            horizontal="left"
            vertical="bottom"
            sx={{ zIndex: 4000 }}
        />
    );
};
