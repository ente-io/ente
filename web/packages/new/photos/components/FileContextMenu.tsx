import {
    AddSquareIcon,
    ArrowRight02Icon,
    Clock02Icon,
    Delete02Icon,
    Download01Icon,
    Download05Icon,
    Location01Icon,
    Navigation03Icon,
    RemoveCircleIcon,
    StarOffIcon,
    Time04Icon,
    Unarchive03Icon,
    UserAdd02Icon,
    ViewIcon,
    ViewOffSlashIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon, type IconSvgElement } from "@hugeicons/react";
import {
    FileActionMenu,
    type ContextMenuPosition,
    type FileActionMenuItem,
} from "ente-new/photos/components/FileActionMenu";
import { StarBorderIcon } from "ente-new/photos/components/icons/StarIcon";
import type { FileContextAction } from "ente-new/photos/utils/file-actions";
import { t } from "i18next";
import React, { memo, useCallback, useMemo } from "react";

export type { ContextMenuPosition } from "ente-new/photos/components/FileActionMenu";

interface FileContextMenuProps {
    /** Whether the menu is open. */
    open: boolean;
    /** The position to anchor the menu at. */
    anchorPosition: ContextMenuPosition | undefined;
    /** Callback when the menu should close. */
    onClose: () => void;
    /** The actions to display in the menu. */
    actions: FileContextAction[];
    /** Callback when an action is selected. */
    onAction: (action: FileContextAction) => void;
    /** Number of files currently selected. */
}

interface ActionConfig {
    label: string;
    Icon: React.ReactNode;
    isDestructive?: boolean;
}

const hugeIcon = (icon: IconSvgElement, size = 20) => (
    <HugeiconsIcon icon={icon} size={size} />
);

const actionConfigs: Record<FileContextAction, ActionConfig> = {
    sendLink: { label: "Send link", Icon: hugeIcon(Navigation03Icon) },
    download: { label: "download", Icon: hugeIcon(Download01Icon) },
    fixTime: { label: "fix_creation_time", Icon: hugeIcon(Time04Icon) },
    editLocation: { label: "edit_location", Icon: hugeIcon(Location01Icon) },
    favorite: { label: "favorite", Icon: <StarBorderIcon fontSize="small" /> },
    unfavorite: { label: "un_favorite", Icon: hugeIcon(StarOffIcon) },
    archive: { label: "archive", Icon: hugeIcon(Download05Icon) },
    unarchive: { label: "unarchive", Icon: hugeIcon(Unarchive03Icon) },
    hide: { label: "hide", Icon: hugeIcon(ViewOffSlashIcon) },
    unhide: { label: "unhide", Icon: hugeIcon(ViewIcon) },
    trash: {
        label: "delete",
        Icon: hugeIcon(Delete02Icon),
        isDestructive: true,
    },
    deletePermanently: {
        label: "delete_permanently",
        Icon: hugeIcon(Delete02Icon),
        isDestructive: true,
    },
    restore: { label: "restore", Icon: hugeIcon(Clock02Icon) },
    addToAlbum: { label: "add", Icon: hugeIcon(AddSquareIcon) },
    moveToAlbum: { label: "move", Icon: hugeIcon(ArrowRight02Icon) },
    removeFromAlbum: { label: "remove", Icon: hugeIcon(RemoveCircleIcon) },
    addPerson: { label: "add_a_person", Icon: hugeIcon(UserAdd02Icon) },
};

/**
 * Context menu for file operations, displayed on right-click of file
 * thumbnails.
 *
 * This component renders a single Menu instance that is positioned based on
 * mouse coordinates. It should be rendered once at the FileList level, not per
 * thumbnail.
 */
export const FileContextMenu: React.FC<FileContextMenuProps> = memo(
    ({ open, anchorPosition, onClose, actions, onAction }) => {
        const handleActionClick = useCallback(
            (action: FileContextAction) => {
                onAction(action);
            },
            [onAction],
        );

        // Separate primary and destructive actions in a single pass
        const [primaryActions, destructiveActions] = useMemo(() => {
            const primary: FileContextAction[] = [];
            const destructive: FileContextAction[] = [];
            for (const action of actions) {
                if (actionConfigs[action].isDestructive) {
                    destructive.push(action);
                } else {
                    primary.push(action);
                }
            }
            return [primary, destructive];
        }, [actions]);

        const items = useMemo<FileActionMenuItem[]>(() => {
            const actionToMenuItem = (
                action: FileContextAction,
                tone?: FileActionMenuItem["tone"],
            ): FileActionMenuItem => {
                const { label, Icon } = actionConfigs[action];
                return {
                    id: action,
                    label: t(label),
                    icon: Icon,
                    onClick: () => handleActionClick(action),
                    tone,
                };
            };

            return [
                ...primaryActions.map((action) => actionToMenuItem(action)),
                ...destructiveActions.map((action) =>
                    actionToMenuItem(action, "destructive"),
                ),
            ];
        }, [destructiveActions, handleActionClick, primaryActions]);

        return (
            <FileActionMenu
                open={open}
                onClose={onClose}
                anchorPosition={anchorPosition}
                items={items}
            />
        );
    },
);

FileContextMenu.displayName = "FileContextMenu";
