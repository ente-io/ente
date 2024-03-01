import { ButtonProps } from "@mui/material/Button";
import { ReactNode } from "react";

export type NotificationAttributes =
    | MessageSubTextNotificationAttributes
    | TitleCaptionNotificationAttributes;

interface MessageSubTextNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    message?: JSX.Element | string;
    subtext?: JSX.Element | string;
    title?: never;
    caption?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

interface TitleCaptionNotificationAttributes {
    startIcon?: ReactNode;
    variant: ButtonProps["color"];
    title?: JSX.Element | string;
    caption?: JSX.Element | string;
    message?: never;
    subtext?: never;
    onClick: () => void;
    endIcon?: ReactNode;
}

export type SetNotificationAttributes = React.Dispatch<
    React.SetStateAction<NotificationAttributes>
>;
