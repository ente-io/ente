import ClockIcon from "@mui/icons-material/AccessTime";
import AddIcon from "@mui/icons-material/Add";
import ArchiveIcon from "@mui/icons-material/ArchiveOutlined";
import MoveIcon from "@mui/icons-material/ArrowForward";
import DeleteIcon from "@mui/icons-material/Delete";
import DownloadIcon from "@mui/icons-material/Download";
import EditLocationAltIcon from "@mui/icons-material/EditLocationAlt";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import RemoveIcon from "@mui/icons-material/RemoveCircleOutline";
import RestoreIcon from "@mui/icons-material/Restore";
import UnArchiveIcon from "@mui/icons-material/Unarchive";
import VisibilityOffOutlinedIcon from "@mui/icons-material/VisibilityOffOutlined";
import VisibilityOutlinedIcon from "@mui/icons-material/VisibilityOutlined";
import type { SvgIconProps } from "@mui/material";
import {
    ListItemIcon,
    ListItemText,
    Menu,
    MenuItem,
    styled,
} from "@mui/material";
import { StarBorderIcon } from "ente-new/photos/components/icons/StarIcon";
import type { FileContextAction } from "ente-new/photos/utils/file-actions";
import { t } from "i18next";
import React, { memo, useCallback, useMemo } from "react";

/**
 * Position for anchoring the context menu.
 */
export interface ContextMenuPosition {
    top: number;
    left: number;
}

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
    Icon: React.ComponentType<SvgIconProps>;
    isDestructive?: boolean;
}

const actionConfigs: Record<FileContextAction, ActionConfig> = {
    download: { label: "download", Icon: DownloadIcon },
    fixTime: { label: "fix_creation_time", Icon: ClockIcon },
    editLocation: { label: "edit_location", Icon: EditLocationAltIcon },
    favorite: { label: "favorite", Icon: StarBorderIcon },
    archive: { label: "archive", Icon: ArchiveIcon },
    unarchive: { label: "unarchive", Icon: UnArchiveIcon },
    hide: { label: "hide", Icon: VisibilityOffOutlinedIcon },
    unhide: { label: "unhide", Icon: VisibilityOutlinedIcon },
    trash: { label: "delete", Icon: DeleteIcon, isDestructive: true },
    deletePermanently: {
        label: "delete_permanently",
        Icon: DeleteIcon,
        isDestructive: true,
    },
    restore: { label: "restore", Icon: RestoreIcon },
    addToAlbum: { label: "add", Icon: AddIcon },
    moveToAlbum: { label: "move", Icon: MoveIcon },
    removeFromAlbum: { label: "remove", Icon: RemoveIcon },
    addPerson: { label: "add_a_person", Icon: PersonAddIcon },
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
                onClose();
                onAction(action);
            },
            [onClose, onAction],
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

        return (
            <StyledMenu
                open={open}
                onClose={onClose}
                anchorReference="anchorPosition"
                anchorPosition={anchorPosition}
                slotProps={{
                    root: {
                        onContextMenu: (e: React.MouseEvent) =>
                            e.preventDefault(),
                    },
                }}
            >
                {primaryActions.map((action) => {
                    const { label, Icon } = actionConfigs[action];
                    return (
                        <StyledMenuItem
                            key={action}
                            onClick={() => handleActionClick(action)}
                        >
                            <ListItemIcon>
                                <Icon fontSize="small" />
                            </ListItemIcon>
                            <ListItemText>{t(label)}</ListItemText>
                        </StyledMenuItem>
                    );
                })}

                {destructiveActions.map((action) => {
                    const { label, Icon } = actionConfigs[action];
                    return (
                        <StyledMenuItem
                            key={action}
                            onClick={() => handleActionClick(action)}
                            sx={{
                                color: "critical.main",
                                "&:hover": {
                                    backgroundColor: "critical.main",
                                    color: "#fff",
                                },
                            }}
                        >
                            <ListItemIcon sx={{ color: "inherit" }}>
                                <Icon fontSize="small" />
                            </ListItemIcon>
                            <ListItemText>{t(label)}</ListItemText>
                        </StyledMenuItem>
                    );
                })}
            </StyledMenu>
        );
    },
);

FileContextMenu.displayName = "FileContextMenu";

const StyledMenu = styled(Menu)(({ theme }) => ({
    "& .MuiPaper-root": {
        backgroundColor: "#1f1f1f",
        minWidth: 220,
        borderRadius: 12,
        boxShadow: "0 8px 24px rgba(0, 0, 0, 0.35)",
        marginTop: 6,
    },
    "& .MuiList-root": { padding: theme.spacing(1) },
    ...theme.applyStyles("dark", {
        "& .MuiPaper-root": {
            backgroundColor: "#161616",
            boxShadow: "0 8px 24px rgba(0, 0, 0, 0.6)",
        },
    }),
}));

const StyledMenuItem = styled(MenuItem)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: theme.spacing(1.5, 2),
    borderRadius: 10,
    color: "#f5f5f5",
    fontSize: 15,
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.08)" },
    "& .MuiListItemIcon-root": { minWidth: 0, color: "inherit" },
    "& .MuiListItemText-root": { margin: 0 },
    "& .MuiListItemText-primary": { color: "inherit", fontSize: "inherit" },
}));
