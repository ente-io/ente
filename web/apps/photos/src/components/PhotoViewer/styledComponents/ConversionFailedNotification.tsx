import Notification from "components/Notification";
import { t } from "i18next";

interface Iprops {
    open: boolean;
    onClose: () => void;
    onClick: () => void;
}

export const ConversionFailedNotification = ({
    open,
    onClose,
    onClick,
}: Iprops) => {
    return (
        <Notification
            open={open}
            onClose={onClose}
            attributes={{
                variant: "secondary",
                subtext: t("CONVERSION_FAILED_NOTIFICATION_MESSAGE"),
                onClick: onClick,
            }}
            horizontal="right"
            vertical="bottom"
            sx={{ zIndex: 4000 }}
        />
    );
};
