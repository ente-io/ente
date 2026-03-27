import { type NotificationAttributes } from "ente-new/photos/components/Notification";
import { useCallback, useState } from "react";

/**
 * A React hook for simplifying the provisioning of a {@link showMiniDialog}
 * function to inject in app contexts, and of the other props that are needed to
 * be passed to the {@link AttributedMiniDialog}.
 */
export const useNotification = () => {
    const [attributes, setAttributes] = useState<
        NotificationAttributes | undefined
    >(undefined);

    const [open, setOpen] = useState(false);

    const showNotification = useCallback(
        (attributes: NotificationAttributes) => {
            setAttributes(attributes);
            setOpen(true);
        },
        [],
    );

    const handleClose = useCallback(() => setOpen(false), []);

    return {
        showNotification,
        notificationProps: { open, onClose: handleClose, attributes },
    };
};
