import type { ButtonProps } from "@mui/material/Button";
import type { ReactNode } from "react";

export type NotificationAttributes =
    | MessageSubTextNotificationAttributes
    | TitleCaptionNotificationAttributes;

interface MessageSubTextNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    message?: React.JSX.Element | string;
    subtext?: React.JSX.Element | string;
    title?: never;
    caption?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

interface TitleCaptionNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    title?: React.JSX.Element | string;
    caption?: React.JSX.Element | string;
    message?: never;
    subtext?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

export type SetNotificationAttributes = React.Dispatch<
    React.SetStateAction<NotificationAttributes>
>;
