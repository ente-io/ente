import { createContext, useContext } from "react";

export const NotificationContainers = createContext<{
    left: HTMLDivElement | null;
    right: HTMLDivElement | null;
}>({ left: null, right: null });

export const useNotificationContainer = (horizontal: "left" | "right") =>
    useContext(NotificationContainers)[horizontal];
