import { useMediaQuery, type Theme } from "@mui/material";
import { useEffect, useState, useSyncExternalStore } from "react";

interface StackEntry {
    element: HTMLDivElement;
    horizontal: "left" | "right";
    height: number;
}

// Share measured positions across notifications rendered by different owners.
let entries: StackEntry[] = [];
const serverEntries: StackEntry[] = [];
const listeners = new Set<() => void>();
const subscribe = (listener: () => void) => {
    listeners.add(listener);
    return () => {
        listeners.delete(listener);
    };
};
const getSnapshot = () => entries;
const getServerSnapshot = () => serverEntries;
const publish = () => {
    listeners.forEach((listener) => listener());
};

export const useNotificationStack = (
    active: boolean,
    horizontal: "left" | "right",
) => {
    const [element, ref] = useState<HTMLDivElement | null>(null);
    const stack = useSyncExternalStore(
        subscribe,
        getSnapshot,
        getServerSnapshot,
    );
    // Left and right notifications share the available width on small screens.
    const mobile = useMediaQuery((theme: Theme) =>
        theme.breakpoints.down("md"),
    );

    useEffect(() => {
        if (!active || !element) return;
        const height = () => element.getBoundingClientRect().height;
        entries = [...entries, { element, horizontal, height: height() }];
        publish();
        const observer = new ResizeObserver(() => {
            const nextHeight = height();
            if (
                entries.find((entry) => entry.element === element)?.height ===
                nextHeight
            )
                return;
            entries = entries.map((entry) =>
                entry.element === element
                    ? { ...entry, height: nextHeight }
                    : entry,
            );
            publish();
        });
        observer.observe(element);
        return () => {
            observer.disconnect();
            entries = entries.filter((entry) => entry.element !== element);
            publish();
        };
    }, [active, element, horizontal]);

    let offset = 0;
    for (const entry of stack) {
        if (entry.element === element) break;
        if (mobile || entry.horizontal === horizontal)
            offset += entry.height + 16;
    }
    return { ref, offset };
};
