import {
    ListItemIcon,
    ListItemText,
    Menu,
    MenuItem,
    styled,
} from "@mui/material";
import React, { memo, useCallback } from "react";

export interface ContextMenuPosition {
    top: number;
    left: number;
}

export type FileActionMenuItemTone = "default" | "destructive" | "muted";

export interface FileActionMenuItem {
    id: string;
    label: React.ReactNode;
    icon?: React.ReactNode;
    onClick: () => void;
    disabled?: boolean;
    tone?: FileActionMenuItemTone;
    divider?: boolean;
}

interface FileActionMenuProps {
    open: boolean;
    onClose: () => void;
    items: FileActionMenuItem[];
    anchorEl?: HTMLElement | null;
    anchorPosition?: ContextMenuPosition;
    id?: string;
    labelledBy?: string;
}

const menuItemToneSx = (tone: FileActionMenuItemTone = "default") => {
    switch (tone) {
        case "destructive":
            return {
                color: "critical.main",
                "&:hover": { backgroundColor: "critical.main", color: "#fff" },
                "& .MuiListItemIcon-root": { color: "inherit" },
            };
        case "muted":
            return { color: "fixed.dark.text.faint" };
        default:
            return undefined;
    }
};

export const FileActionMenu: React.FC<FileActionMenuProps> = memo(
    ({ open, onClose, items, anchorEl, anchorPosition, id, labelledBy }) => {
        const handleItemClick = useCallback(
            (item: FileActionMenuItem) => {
                onClose();
                item.onClick();
            },
            [onClose],
        );

        return (
            <StyledMenu
                open={open}
                onClose={onClose}
                disableAutoFocusItem
                id={id}
                anchorReference={anchorPosition ? "anchorPosition" : "anchorEl"}
                anchorEl={anchorPosition ? undefined : anchorEl}
                anchorPosition={anchorPosition}
                slotProps={{
                    root: {
                        onContextMenu: (e: React.MouseEvent) =>
                            e.preventDefault(),
                    },
                    list: labelledBy
                        ? { "aria-labelledby": labelledBy }
                        : undefined,
                }}
            >
                {items.map((item) => (
                    <StyledMenuItem
                        key={item.id}
                        disabled={item.disabled}
                        divider={item.divider}
                        onClick={() => handleItemClick(item)}
                        sx={menuItemToneSx(item.tone)}
                    >
                        {item.icon ? (
                            <ListItemIcon sx={{ color: "inherit" }}>
                                {item.icon}
                            </ListItemIcon>
                        ) : null}
                        <ListItemText primary={item.label} />
                    </StyledMenuItem>
                ))}
            </StyledMenu>
        );
    },
);

FileActionMenu.displayName = "FileActionMenu";

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
    "&.MuiMenuItem-divider": {
        borderColor: theme.vars.palette.fixed.dark.divider,
    },
    "& .MuiListItemIcon-root": { minWidth: 0, color: "inherit" },
    "& .MuiListItemText-root": { margin: 0 },
    "& .MuiListItemText-primary": { color: "inherit", fontSize: "inherit" },
}));
