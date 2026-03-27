import { useSaveGroups } from "@/gallery/components/utils/save-groups";
import { type ComponentProps } from "react";
import { DownloadStatusNotifications } from "./DownloadStatusNotifications";

type ActiveDownloadStatusNotificationsProps = Omit<
    ComponentProps<typeof DownloadStatusNotifications>,
    "saveGroups" | "onRemoveSaveGroup"
>;

export const ActiveDownloadStatusNotifications: React.FC<
    ActiveDownloadStatusNotificationsProps
> = (props) => {
    const { saveGroups, onRemoveSaveGroup } = useSaveGroups();

    return (
        <DownloadStatusNotifications
            saveGroups={saveGroups}
            onRemoveSaveGroup={onRemoveSaveGroup}
            {...props}
        />
    );
};
