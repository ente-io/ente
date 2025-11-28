import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import CloseIcon from "@mui/icons-material/Close";
import PhotoOutlinedIcon from "@mui/icons-material/PhotoOutlined";
import VideocamOutlinedIcon from "@mui/icons-material/VideocamOutlined";
import {
    Box,
    Drawer,
    IconButton,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import React from "react";
import type { DecryptedFileInfo } from "../types/file-share";

interface FileInfoPanelProps {
    open: boolean;
    onClose: () => void;
    fileInfo: DecryptedFileInfo;
}

export const FileInfoPanel: React.FC<FileInfoPanelProps> = ({
    open,
    onClose,
    fileInfo,
}) => {
    const creationDate = fileInfo.uploadedTime
        ? new Date(fileInfo.uploadedTime / 1000)
        : undefined;

    const formattedDate = creationDate
        ? creationDate.toLocaleDateString(undefined, {
              weekday: "short",
              day: "numeric",
              month: "short",
              year: "numeric",
          })
        : "Unknown";

    const formattedTime = creationDate
        ? creationDate.toLocaleTimeString(undefined, {
              hour: "numeric",
              minute: "2-digit",
          })
        : "";

    const formattedSize = formatFileSize(fileInfo.fileSize);

    const FileTypeIcon =
        fileInfo.fileType === "video"
            ? VideocamOutlinedIcon
            : PhotoOutlinedIcon;

    return (
        <Drawer
            anchor="right"
            open={open}
            onClose={onClose}
            slotProps={{
                paper: {
                    sx: {
                        maxWidth: "375px",
                        width: "100%",
                        scrollbarWidth: "thin",
                        "&&": { padding: 0 },
                        "&&&": { backgroundColor: "#1c1c1c" },
                    },
                },
            }}
        >
            <Box sx={{ p: 1 }}>
                {/* Titlebar */}
                <Stack sx={{ gap: "4px" }}>
                    <Stack
                        direction="row"
                        sx={{ justifyContent: "space-between" }}
                    >
                        <IconButton onClick={onClose} color="primary">
                            <ArrowBackIcon />
                        </IconButton>
                        <IconButton onClick={onClose} color="secondary">
                            <CloseIcon />
                        </IconButton>
                    </Stack>
                    <Stack sx={{ px: "16px", gap: "4px" }}>
                        <Typography variant="h3">Info</Typography>
                        <Box sx={{ minHeight: "17px" }} />
                    </Stack>
                </Stack>

                {/* Content */}
                <Stack sx={{ pt: 1, pb: 3, gap: "20px" }}>
                    {/* Spacer like caption area */}
                    <Box sx={{ minHeight: 2 }} />

                    {/* Date */}
                    <InfoItem
                        icon={<CalendarTodayIcon />}
                        title={formattedDate}
                        caption={formattedTime}
                    />

                    {/* File Name & Size */}
                    <InfoItem
                        icon={<FileTypeIcon />}
                        title={fileInfo.fileName}
                        caption={formattedSize}
                    />

                    {/* Owner */}
                    {fileInfo.ownerName && (
                        <Typography
                            variant="small"
                            sx={{
                                m: 2,
                                textAlign: "right",
                                color: "text.muted",
                            }}
                        >
                            {`Shared by ${fileInfo.ownerName}`}
                        </Typography>
                    )}
                </Stack>
            </Box>
        </Drawer>
    );
};

interface InfoItemProps {
    icon: React.ReactNode;
    title?: string;
    caption?: React.ReactNode;
}

const InfoItem: React.FC<InfoItemProps> = ({ icon, title, caption }) => (
    <Stack
        direction="row"
        sx={{ alignItems: "flex-start", flex: 1, gap: "12px" }}
    >
        <InfoItemIconContainer>{icon}</InfoItemIconContainer>
        <Stack sx={{ flex: 1, mt: "4px", gap: "4px" }}>
            <Typography sx={{ wordBreak: "break-all" }}>{title}</Typography>
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {caption}
            </Typography>
        </Stack>
    </Stack>
);

const InfoItemIconContainer = styled("div")(
    ({ theme }) => `
    width: 48px;
    aspect-ratio: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: ${theme.vars.palette.stroke.muted};
    & svg {
        stroke: currentColor;
        stroke-width: 1px;
    }
`,
);

const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
};
