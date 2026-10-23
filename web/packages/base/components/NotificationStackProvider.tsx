import { Box } from "@mui/material";
import { NotificationContainers } from "ente-base/components/utils/notification-container";
import { useState, type ReactNode } from "react";

/** Shared CSS stacks for notifications owned by different parts of the app. */
export const NotificationStackProvider = ({
    children,
}: {
    children: ReactNode;
}) => {
    const [left, setLeft] = useState<HTMLDivElement | null>(null);
    const [right, setRight] = useState<HTMLDivElement | null>(null);
    return (
        <NotificationContainers value={{ left, right }}>
            {children}
            <Box
                sx={{
                    position: "fixed",
                    inset: { xs: "auto 16px 16px", sm: "auto 24px 24px" },
                    display: "flex",
                    flexDirection: { xs: "column", md: "row" },
                    alignItems: "flex-end",
                    justifyContent: "space-between",
                    gap: 2,
                    pointerEvents: "none",
                    zIndex: (theme) => theme.zIndex.snackbar,
                }}
            >
                {(["left", "right"] as const).map((side) => (
                    <Box
                        key={side}
                        ref={side === "left" ? setLeft : setRight}
                        sx={{
                            display: "flex",
                            flexDirection: "column-reverse",
                            gap: 2,
                            ml: side === "right" ? { md: "auto" } : undefined,
                            alignItems:
                                side === "left"
                                    ? { xs: "flex-end", md: "flex-start" }
                                    : "flex-end",
                            "&:empty": { display: "none" },
                        }}
                    />
                ))}
            </Box>
        </NotificationContainers>
    );
};
