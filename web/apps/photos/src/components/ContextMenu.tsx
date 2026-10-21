import { Menu, MenuItem, styled } from "@mui/material";

export const ContextMenu = styled(Menu)(({ theme }) => ({
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

export const ContextMenuItem = styled(MenuItem, {
    shouldForwardProp: (prop) => prop !== "destructive",
})<{ destructive?: boolean }>(({ theme, destructive }) => ({
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
    ...(destructive && {
        color: theme.vars.palette.critical.main,
        "&:hover": {
            backgroundColor: theme.vars.palette.critical.main,
            color: "#fff",
        },
    }),
}));
