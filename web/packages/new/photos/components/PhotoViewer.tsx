import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { t } from "i18next";
import { aboveGalleryContentZ } from "./utils/z-index";

// const confirmTrashFile = (file: EnteFile) => {
//     if (!file || !isOwnFile || isTrashCollection) {
//         return;
//     }
//     showMiniDialog({
//
//         message: t("trash_file_message"),
//         continue: {
//             text: t("move_to_trash"),
//             color: "critical",
//             action: () => trashFile(file),
//             autoFocus: true,
//         },
//     });
// };

type ConfirmDeleteFileDialogProps = ModalVisibilityProps & {
    /**
     * Called when the user confirms the deletion.
     *
     * The delete button will show an activity indicator until this async
     * operation completes.
     */
    onConfirm: () => Promise<void>;
};

/**
 * A bespoke variant of AttributedMiniDialog for use by the delete file
 * confirmation prompt that we show in the image viewer.
 *
 * - It auto focuses the primary action.
 * - It uses a lighter backdrop in light mode.
 */
export const ConfirmDeleteFileDialog: React.FC<
    ConfirmDeleteFileDialogProps
> = ({ onConfirm, ...visibilityProps }) => (
    <TitledMiniDialog
        {...visibilityProps}
        title={t("trash_file_title")}
        sx={(theme) => ({
            zIndex: aboveGalleryContentZ,
            // See: [Note: Lighter backdrop for overlays on photo viewer]
            ...theme.applyStyles("light", {
                ".MuiBackdrop-root": {
                    backgroundColor: theme.vars.palette.backdrop.faint,
                },
            }),
        })}
    >
        <FocusVisibleButton fullWidth onClick={onConfirm}>
            {"Test"}
        </FocusVisibleButton>
    </TitledMiniDialog>
);
