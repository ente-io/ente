import { useSaveGroups } from "@/shared/state/save-groups";
import dynamic from "next/dynamic";
import { type DownloadStatusNotificationsProps } from "./DownloadStatusNotifications";

const LazyDownloadStatusNotifications =
    dynamic<DownloadStatusNotificationsProps>(
        () =>
            import("./DownloadStatusNotifications").then(
                ({ DownloadStatusNotifications }) =>
                    DownloadStatusNotifications,
            ),
        { ssr: false },
    );

type ActiveDownloadStatusNotificationsProps = Omit<
    DownloadStatusNotificationsProps,
    "saveGroups" | "onRemoveSaveGroup"
>;

export const ActiveDownloadStatusNotifications: React.FC<
    ActiveDownloadStatusNotificationsProps
> = (props) => {
    const { saveGroups, onRemoveSaveGroup } = useSaveGroups();

    if (!saveGroups.length) {
        return null;
    }

    return (
        <LazyDownloadStatusNotifications
            saveGroups={saveGroups}
            onRemoveSaveGroup={onRemoveSaveGroup}
            {...props}
        />
    );
};
