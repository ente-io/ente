import {
    Box,
    ButtonBase,
    CircularProgress,
    Stack,
    Typography,
} from "@mui/material";
import { SingleInputForm } from "ente-base/components/SingleInputForm";
import { Notification } from "ente-new/photos/components/Notification";
import React from "react";
import { useCollectionShare } from "../../hooks/useCollectionShare";
import { type SharedCollectionItemInfo } from "../../services/collection-share";
import { formatFileSize } from "../../services/file-share";
import { getLockerFileIcon } from "../../utils/file-type";
import { PublicShareScaffold } from "./PublicShareScaffold";
import { SharedItemDetails } from "./SharedItemDetails";

const lockerTypeLabel = (lockerType: string) => {
    switch (lockerType) {
        case "note":
            return "Note";
        case "accountCredential":
            return "Secret";
        case "physicalRecord":
            return "Location";
        case "emergencyContact":
            return "Emergency Contact";
        default:
            return lockerType;
    }
};

const itemSubtitle = (item: SharedCollectionItemInfo) => {
    if (item.lockerType) {
        return lockerTypeLabel(item.lockerType);
    }

    if (item.fileSize > 0) {
        return formatFileSize(item.fileSize);
    }

    return "File";
};

const contentMaxWidth = 560;

export const CollectionShareView: React.FC = () => {
    const {
        loading,
        requiresPassword,
        downloadingItemID,
        downloadProgress,
        errorTitle,
        error,
        collectionInfo,
        selectedItem,
        notificationAttributes,
        handleItemClick,
        handleCloseItem,
        handleDownload,
        handleSubmitPassword,
        handleCopyContent,
        setNotificationAttributes,
    } = useCollectionShare();

    return (
        <PublicShareScaffold>
            {loading && (
                <Box
                    sx={{
                        flex: 1,
                        width: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    <CircularProgress sx={{ color: "accent.main" }} size={32} />
                </Box>
            )}

            {error && !loading && (
                <Box
                    sx={{
                        flex: 1,
                        width: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        p: 3,
                    }}
                >
                    <Box sx={{ maxWidth: 420, textAlign: "center" }}>
                        <Typography
                            variant="h4"
                            sx={{
                                fontWeight: 700,
                                color: "text.base",
                                mb: 1.5,
                            }}
                        >
                            {errorTitle ?? "Unable to open this collection"}
                        </Typography>
                        <Typography variant="body" sx={{ color: "text.muted" }}>
                            {error}
                        </Typography>
                    </Box>
                </Box>
            )}

            {requiresPassword && !loading && !error && (
                <Box
                    sx={{
                        flex: 1,
                        width: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        p: 3,
                    }}
                >
                    <Box sx={{ width: "100%", maxWidth: 420 }}>
                        <Typography
                            variant="h4"
                            sx={{
                                fontWeight: 700,
                                color: "text.base",
                                mb: 1.5,
                            }}
                        >
                            Password
                        </Typography>
                        <Typography
                            variant="body"
                            sx={{ color: "text.muted", mb: 2 }}
                        >
                            This collection link is password protected.
                        </Typography>
                        <SingleInputForm
                            inputType="password"
                            label="Password"
                            submitButtonColor="primary"
                            submitButtonTitle="Unlock"
                            onSubmit={handleSubmitPassword}
                        />
                    </Box>
                </Box>
            )}

            {/* Item detail view - uses same component as single-file share */}
            {selectedItem && !loading && !requiresPassword && (
                <SharedItemDetails
                    itemInfo={selectedItem}
                    downloading={downloadingItemID === selectedItem.id}
                    onDownload={
                        collectionInfo?.allowDownload && selectedItem.hasObject
                            ? handleDownload
                            : undefined
                    }
                    onCopyContent={(value) => {
                        void handleCopyContent(value);
                    }}
                    onBack={handleCloseItem}
                />
            )}

            {/* Collection list view */}
            {collectionInfo &&
                !loading &&
                !selectedItem &&
                !requiresPassword && (
                    <Box
                        sx={{
                            width: "100%",
                            flex: 1,
                            px: { xs: 2, sm: 3 },
                            pb: "calc(env(safe-area-inset-bottom) + 120px)",
                            pt: { xs: 3, md: 5 },
                        }}
                    >
                        <Stack
                            direction="row"
                            sx={{
                                alignItems: "center",
                                justifyContent: "space-between",
                                gap: 2,
                                maxWidth: contentMaxWidth,
                                mx: "auto",
                                mt: 1,
                                mb: 2.25,
                            }}
                        >
                            <Box sx={{ minWidth: 0 }}>
                                <Typography
                                    variant="h3"
                                    sx={{ fontWeight: "bold", minWidth: 0 }}
                                >
                                    {collectionInfo.name}
                                </Typography>
                                <Typography
                                    variant="small"
                                    sx={{ color: "text.muted", mt: 1 }}
                                >
                                    {collectionInfo.items.length}{" "}
                                    {collectionInfo.items.length === 1
                                        ? "item"
                                        : "items"}
                                </Typography>
                            </Box>
                        </Stack>

                        <Stack
                            sx={{
                                maxWidth: contentMaxWidth,
                                mx: "auto",
                                gap: 1.1,
                                mt: 1.25,
                            }}
                        >
                            {collectionInfo.items.map((item) => {
                                const iconInfo = getLockerFileIcon(
                                    item.fileName,
                                    { lockerType: item.lockerType, size: 20 },
                                );

                                return (
                                    <ButtonBase
                                        key={`${item.collectionID}-${item.id}`}
                                        component="div"
                                        onClick={() => handleItemClick(item)}
                                        sx={(theme) => ({
                                            display: "flex",
                                            width: "100%",
                                            textAlign: "left",
                                            borderRadius: "18px",
                                            overflow: "hidden",
                                            px: 1.5,
                                            py: 1.25,
                                            gap: 1.25,
                                            alignItems: "center",
                                            backgroundColor:
                                                theme.vars.palette.fill.faint,
                                            transition:
                                                "background-color 0.15s",
                                            "&:hover": {
                                                backgroundColor:
                                                    theme.vars.palette.fill
                                                        .faintHover,
                                            },
                                            ...theme.applyStyles("light", {
                                                backgroundColor: "#FFFFFF",
                                                "&:hover": {
                                                    backgroundColor: "#FFFFFF",
                                                },
                                            }),
                                        })}
                                    >
                                        <Box
                                            sx={{
                                                position: "relative",
                                                width: 52,
                                                height: 52,
                                                flexShrink: 0,
                                            }}
                                        >
                                            <Box
                                                sx={{
                                                    position: "relative",
                                                    zIndex: 1,
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                    width: 40,
                                                    height: 40,
                                                    m: "6px",
                                                    borderRadius: "12px",
                                                    backgroundColor:
                                                        iconInfo.backgroundColor,
                                                }}
                                            >
                                                {iconInfo.icon}
                                            </Box>
                                        </Box>
                                        <Box sx={{ flex: 1, minWidth: 0 }}>
                                            <Typography
                                                variant="body"
                                                sx={{
                                                    minWidth: 0,
                                                    fontWeight: "regular",
                                                    lineHeight: 1.45,
                                                }}
                                                noWrap
                                            >
                                                {item.fileName}
                                            </Typography>
                                            <Typography
                                                variant="small"
                                                sx={{
                                                    color: "text.muted",
                                                    mt: 0.25,
                                                }}
                                                noWrap
                                            >
                                                {itemSubtitle(item)}
                                            </Typography>
                                        </Box>
                                        {downloadingItemID === item.id && (
                                            <Box
                                                sx={{
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                    width: 28,
                                                    height: 28,
                                                    flexShrink: 0,
                                                }}
                                            >
                                                <CircularProgress
                                                    size={20}
                                                    thickness={5}
                                                    variant={
                                                        downloadProgress !==
                                                        null
                                                            ? "determinate"
                                                            : "indeterminate"
                                                    }
                                                    value={
                                                        downloadProgress ??
                                                        undefined
                                                    }
                                                    sx={{
                                                        color: "accent.main",
                                                    }}
                                                />
                                            </Box>
                                        )}
                                    </ButtonBase>
                                );
                            })}
                        </Stack>
                    </Box>
                )}

            <Notification
                open={!!notificationAttributes}
                onClose={() => setNotificationAttributes(undefined)}
                attributes={notificationAttributes}
            />
        </PublicShareScaffold>
    );
};
