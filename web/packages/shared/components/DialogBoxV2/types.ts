import type { ButtonProps } from "@mui/material";

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
    content?: React.ReactNode;
    close?: {
        text?: string;
        variant?: ButtonProps["color"];
        action?: () => void;
    };
    proceed?: {
        text: string;
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
