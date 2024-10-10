import ErrorOutline from "@mui/icons-material/ErrorOutline";
import { t } from "i18next";
import { useCallback, useState } from "react";
import type { MiniDialogAttributes } from "../MiniDialog";

/**
 * A React hook for simplifying the provisioning of a {@link showMiniDialog}
 * function to inject in app contexts, and the other props that are needed for
 * to pass on to the {@link AttributedMiniDialog}.
 */
export const useAttributedMiniDialog = () => {
    const [miniDialogAttributes, setMiniDialogAttributes] = useState<
        MiniDialogAttributes | undefined
    >();

    const [openMiniDialog, setOpenMiniDialog] = useState(false);

    const showMiniDialog = useCallback((attributes: MiniDialogAttributes) => {
        setMiniDialogAttributes(attributes);
        setOpenMiniDialog(true);
    }, []);

    const onCloseMiniDialog = useCallback(() => setOpenMiniDialog(false), []);

    return {
        showMiniDialog,
        miniDialogProps: {
            open: openMiniDialog,
            onClose: onCloseMiniDialog,
            attributes: miniDialogAttributes,
        },
    };
};

/**
 * A convenience function to construct {@link MiniDialogAttributes} for showing
 * error dialogs.
 *
 * It takes one or two arguments.
 *
 * - If both are provided, then the first one is taken as the title and the
 *   second one as the message.
 *
 * - Otherwise it sets a default title and use the only argument as the message.
 */
export const errorDialogAttributes = (
    messageOrTitle: string,
    optionalMessage?: string,
): MiniDialogAttributes => {
    const title = optionalMessage ? messageOrTitle : t("error");
    const message = optionalMessage ? optionalMessage : messageOrTitle;

    return {
        title,
        icon: <ErrorOutline />,
        message,
        continue: { color: "critical" },
        cancel: false,
    };
};

export const genericErrorDialogAttributes = () =>
    errorDialogAttributes(t("generic_error"));
