import dynamic from "next/dynamic";

export const LazyNotification = dynamic(
    () =>
        import("@/shared/ui/feedback/Notification").then(
            ({ Notification }) => Notification,
        ),
    { ssr: false },
);

export const LazyAttributedMiniDialog = dynamic(
    () =>
        import("ente-base/components/MiniDialog").then(
            ({ AttributedMiniDialog }) => AttributedMiniDialog,
        ),
    { ssr: false },
);
