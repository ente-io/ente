import type { ButtonProps } from "@mui/material";

/**
 * Customize the properties of the dialog box.
 *
 * Our custom dialog box helpers are meant for small message boxes, usually
 * meant to confirm some user action. If more customization is needed, it might
 * be a better idea to reach out for a bespoke MUI {@link DialogBox} instead.
 */
export interface DialogBoxAttributesV2 {
    icon?: React.ReactNode;
    /**
     * The dialog's title
     *
     * Usually this will be a string, but it can be any {@link ReactNode}. Note
     * that it always gets wrapped in a Typography element to set the font
     * style, so if your ReactNode wants to do its own thing, it'll need to
     * reset or override these customizations.
     */
    title?: React.ReactNode;
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    /**
     * The dialog's content.
     */
    content?: React.ReactNode;
    /**
     * Customize the cancel (dismiss) action button offered by the dialog box.
     *
     * Usually dialog boxes should have a cancel action, but this can be skipped
     * to only show one of the other types of buttons.
     */
    close?: {
        /** The string to use as the label for the cancel button. */
        text?: string;
        /** The color of the button. */
        variant?: ButtonProps["color"];
        /**
         * The function to call when the user cancels.
         *
         * If provided, this callback is invoked before closing the dialog.
         */
        action?: () => void;
    };
    /**
     * Customize the primary action button offered by the dialog box.
     */
    proceed?: {
        /** The string to use as the label for the primary action. */
        text: string;
        /** The function to call when the user presses the primary action button. */
        action: (setLoading?: (value: boolean) => void) => void | Promise<void>;
        variant?: ButtonProps["color"];
        disabled?: boolean;
    };
    secondary?: {
        text: string;
        action: () => void;
        variant?: ButtonProps["color"];
        disabled?: boolean;
    };
    buttons?: {
        text: string;
        action: () => void;
        variant: ButtonProps["color"];
        disabled?: boolean;
    }[];
    buttonDirection?: "row" | "column";
}
