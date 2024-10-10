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
