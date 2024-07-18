import type { ButtonProps } from "@mui/material";

export interface DialogBoxAttributes {
    icon?: React.ReactNode;
    title?: string;
    /**
     * Set this to `true` to prevent the dialog from being closed when the user
     * clicks the backdrop outside the dialog.
     */
    staticBackdrop?: boolean;
    nonClosable?: boolean;
    content?: any;
    close?: {
        text?: string;
        variant?: ButtonProps["color"];
        action?: () => void;
    };
    proceed?: {
        text: string;
        action: () => void;
        variant?: ButtonProps["color"];
        disabled?: boolean;
    };
    secondary?: {
        text: string;
        action: () => void;
        variant: ButtonProps["color"];
        disabled?: boolean;
    };
}

export type SetDialogBoxAttributes = React.Dispatch<
    React.SetStateAction<DialogBoxAttributes>
>;
