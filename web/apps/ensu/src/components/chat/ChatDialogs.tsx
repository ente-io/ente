import {
    ArrowRight01Icon,
    Bug01Icon,
    Cancel01Icon,
    Key01Icon,
    Login01Icon,
    Settings01Icon,
    SlidersHorizontalIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    IconButton,
    ListItemButton,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import type { SxProps, Theme } from "@mui/material/styles";
import { DevSettings } from "ente-new/photos/components/DevSettings";
import {
    Notification,
    type NotificationAttributes,
} from "ente-new/photos/components/Notification";
import React, { memo } from "react";

interface IconProps {
    size: number;
    strokeWidth: number;
}

interface SuggestedModel {
    name: string;
    url: string;
    mmproj?: string;
}

type ModelGateStatus =
    | "checking"
    | "missing"
    | "preloading"
    | "downloading"
    | "ready"
    | "error";

export interface ChatDialogsProps {
    showSettingsModal: boolean;
    closeSettingsModal: () => void;
    dialogPaperSx: SxProps<Theme>;
    dialogTitleSx: SxProps<Theme>;
    actionButtonSx: SxProps<Theme>;
    settingsItemSx: SxProps<Theme>;
    smallIconProps: IconProps;
    compactIconProps: IconProps;
    isLoggedIn: boolean;
    signedInEmail?: string | null;
    saveLogs: () => void | Promise<void>;
    handleLogout: () => void;
    openLoginFromChat: () => void;
    openPasskeysFromChat: () => void;
    showComingSoon: boolean;
    setShowComingSoon: React.Dispatch<React.SetStateAction<boolean>>;
    logoSrc: string;
    logoFilter: string | undefined;
    developerSettingsEnabled: boolean;
    modelSettingsEnabled: boolean;
    showDeveloperMenu: boolean;
    closeDeveloperMenu: () => void;
    openModelSettings: () => void;
    openDevSettings: () => void;
    isSmall: boolean;
    deleteSessionId: string | null;
    deleteSessionLabel: string;
    handleCancelDeleteSession: () => void;
    handleConfirmDeleteSession: () => void | Promise<void>;
    showModelSettings: boolean;
    closeModelSettings: () => void;
    useCustomModel: boolean;
    defaultModelName: string;
    loadedModelName: string | null;
    allowMmproj: boolean;
    isTauriRuntime: boolean;
    modelUrl: string;
    setModelUrl: React.Dispatch<React.SetStateAction<string>>;
    modelUrlError: string | null;
    mmprojUrl: string;
    setMmprojUrl: React.Dispatch<React.SetStateAction<string>>;
    mmprojError: string | null;
    suggestedModels: SuggestedModel[];
    handleFillSuggestion: (url: string, mmproj?: string) => void;
    contextLength: string;
    setContextLength: React.Dispatch<React.SetStateAction<string>>;
    contextError: string | null;
    maxTokens: string;
    setMaxTokens: React.Dispatch<React.SetStateAction<string>>;
    maxTokensError: string | null;
    isSavingModel: boolean;
    handleSaveModel: () => void;
    handleUseDefaultModel: () => void;
    syncNotificationOpen: boolean;
    setSyncNotificationOpen: React.Dispatch<React.SetStateAction<boolean>>;
    syncNotification?: NotificationAttributes;
    showDevSettings: boolean;
    closeDevSettings: () => void;
    modelGateStatus: ModelGateStatus;
}

export const ChatDialogs = memo(
    ({
        showSettingsModal,
        closeSettingsModal,
        dialogPaperSx,
        dialogTitleSx,
        actionButtonSx,
        settingsItemSx,
        smallIconProps,
        compactIconProps,
        isLoggedIn,
        signedInEmail,
        saveLogs,
        handleLogout,
        openLoginFromChat,
        openPasskeysFromChat,
        showComingSoon,
        setShowComingSoon,
        logoSrc,
        logoFilter,
        developerSettingsEnabled,
        modelSettingsEnabled,
        showDeveloperMenu,
        closeDeveloperMenu,
        openModelSettings,
        openDevSettings,
        isSmall,
        deleteSessionId,
        deleteSessionLabel,
        handleCancelDeleteSession,
        handleConfirmDeleteSession,
        showModelSettings,
        closeModelSettings,
        useCustomModel,
        defaultModelName,
        loadedModelName,
        allowMmproj,
        isTauriRuntime,
        modelUrl,
        setModelUrl,
        modelUrlError,
        mmprojUrl,
        setMmprojUrl,
        mmprojError,
        suggestedModels,
        handleFillSuggestion,
        contextLength,
        setContextLength,
        contextError,
        maxTokens,
        setMaxTokens,
        maxTokensError,
        isSavingModel,
        handleSaveModel,
        handleUseDefaultModel,
        syncNotificationOpen,
        setSyncNotificationOpen,
        syncNotification,
        showDevSettings,
        closeDevSettings,
        modelGateStatus,
    }: ChatDialogsProps) => (
        <>
            <Dialog
                open={showSettingsModal}
                onClose={closeSettingsModal}
                maxWidth="xs"
                fullWidth
                slotProps={{
                    paper: {
                        sx: [
                            ...(Array.isArray(dialogPaperSx)
                                ? (dialogPaperSx as SxProps<Theme>[])
                                : [dialogPaperSx]),
                            {
                                maxHeight:
                                    "min(500px, calc(var(--ensu-viewport-height, 100svh) - 32px))",
                                display: "flex",
                                flexDirection: "column",
                            },
                        ],
                    },
                }}
            >
                <DialogTitle
                    sx={[
                        ...(Array.isArray(dialogTitleSx)
                            ? (dialogTitleSx as SxProps<Theme>[])
                            : [dialogTitleSx]),
                        {
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            gap: 1,
                            pr: 1,
                        },
                    ]}
                >
                    <Box component="span">Settings</Box>
                    <IconButton
                        aria-label="Close settings"
                        onClick={closeSettingsModal}
                        sx={actionButtonSx}
                    >
                        <HugeiconsIcon
                            icon={Cancel01Icon}
                            {...smallIconProps}
                        />
                    </IconButton>
                </DialogTitle>
                <DialogContent sx={{ flex: 1, overflowY: "auto" }}>
                    <Stack sx={{ gap: 2 }}>
                        {isLoggedIn && (
                            <Box
                                sx={{
                                    px: 2,
                                    py: 1.5,
                                    borderRadius: 2,
                                    border: "1px solid",
                                    borderColor: "divider",
                                    bgcolor: "background.default",
                                }}
                            >
                                <Typography
                                    variant="mini"
                                    sx={{ color: "text.muted" }}
                                >
                                    Signed in as
                                </Typography>
                                <Typography variant="small">
                                    {signedInEmail ?? ""}
                                </Typography>
                            </Box>
                        )}

                        <Stack sx={{ gap: 1 }}>
                            <ListItemButton
                                onClick={() => {
                                    closeSettingsModal();
                                    void saveLogs();
                                }}
                                sx={settingsItemSx}
                            >
                                <HugeiconsIcon
                                    icon={Bug01Icon}
                                    {...compactIconProps}
                                />
                                <Typography variant="small" sx={{ flex: 1 }}>
                                    Save logs
                                </Typography>
                            </ListItemButton>

                            {isLoggedIn && (
                                <ListItemButton
                                    onClick={() => {
                                        closeSettingsModal();
                                        openPasskeysFromChat();
                                    }}
                                    sx={settingsItemSx}
                                >
                                    <HugeiconsIcon
                                        icon={Key01Icon}
                                        {...compactIconProps}
                                    />
                                    <Typography
                                        variant="small"
                                        sx={{ flex: 1 }}
                                    >
                                        Passkeys
                                    </Typography>
                                </ListItemButton>
                            )}

                            {isLoggedIn ? (
                                <ListItemButton
                                    onClick={() => {
                                        closeSettingsModal();
                                        handleLogout();
                                    }}
                                    sx={[
                                        ...(Array.isArray(settingsItemSx)
                                            ? (settingsItemSx as SxProps<Theme>[])
                                            : [settingsItemSx]),
                                        { color: "critical.main" },
                                    ]}
                                >
                                    <Typography
                                        variant="small"
                                        sx={{ flex: 1, fontWeight: 600 }}
                                    >
                                        Sign Out
                                    </Typography>
                                </ListItemButton>
                            ) : (
                                <ListItemButton
                                    onClick={() => {
                                        closeSettingsModal();
                                        openLoginFromChat();
                                    }}
                                    sx={settingsItemSx}
                                >
                                    <HugeiconsIcon
                                        icon={Login01Icon}
                                        {...compactIconProps}
                                    />
                                    <Typography
                                        variant="small"
                                        sx={{ flex: 1, fontWeight: 600 }}
                                    >
                                        Sign In to Backup
                                    </Typography>
                                </ListItemButton>
                            )}
                        </Stack>
                    </Stack>
                </DialogContent>
            </Dialog>

            <Dialog
                open={showComingSoon}
                onClose={() => setShowComingSoon(false)}
                maxWidth="xs"
                fullWidth
                slotProps={{ paper: { sx: dialogPaperSx } }}
            >
                <DialogContent>
                    <Stack sx={{ alignItems: "center", gap: 2, py: 2 }}>
                        <Box
                            component="img"
                            src={logoSrc}
                            alt="Coming soon"
                            sx={{
                                height: 48,
                                width: "auto",
                                filter: logoFilter,
                            }}
                        />
                        <Typography variant="h2" sx={dialogTitleSx}>
                            Sign in
                        </Typography>
                        <Typography
                            variant="small"
                            sx={{ color: "text.muted", textAlign: "center" }}
                        >
                            Coming soon
                        </Typography>
                    </Stack>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 3 }}>
                    <Button
                        variant="contained"
                        color="accent"
                        fullWidth
                        onClick={() => setShowComingSoon(false)}
                    >
                        Got it
                    </Button>
                </DialogActions>
            </Dialog>

            {developerSettingsEnabled && (
                <Dialog
                    open={showDeveloperMenu}
                    onClose={closeDeveloperMenu}
                    fullScreen={isSmall}
                    maxWidth="xs"
                    fullWidth
                    slotProps={{ paper: { sx: dialogPaperSx } }}
                >
                    <DialogTitle sx={dialogTitleSx}>
                        Developer Settings
                    </DialogTitle>
                    <DialogContent>
                        <Stack sx={{ gap: 1 }}>
                            {modelSettingsEnabled && (
                                <ListItemButton
                                    onClick={() => {
                                        closeDeveloperMenu();
                                        openModelSettings();
                                    }}
                                    sx={settingsItemSx}
                                >
                                    <HugeiconsIcon
                                        icon={Settings01Icon}
                                        {...compactIconProps}
                                    />
                                    <Typography
                                        variant="small"
                                        sx={{ flex: 1 }}
                                    >
                                        Model settings
                                    </Typography>
                                    <HugeiconsIcon
                                        icon={ArrowRight01Icon}
                                        {...smallIconProps}
                                    />
                                </ListItemButton>
                            )}
                            <ListItemButton
                                onClick={() => {
                                    closeDeveloperMenu();
                                    openDevSettings();
                                }}
                                sx={settingsItemSx}
                            >
                                <HugeiconsIcon
                                    icon={SlidersHorizontalIcon}
                                    {...compactIconProps}
                                />
                                <Typography variant="small" sx={{ flex: 1 }}>
                                    Server endpoint
                                </Typography>
                                <HugeiconsIcon
                                    icon={ArrowRight01Icon}
                                    {...smallIconProps}
                                />
                            </ListItemButton>
                        </Stack>
                    </DialogContent>
                    <DialogActions sx={{ px: 3, pb: 3 }}>
                        <Button
                            onClick={closeDeveloperMenu}
                            color="secondary"
                            fullWidth
                        >
                            Close
                        </Button>
                    </DialogActions>
                </Dialog>
            )}

            <Dialog
                open={Boolean(deleteSessionId)}
                onClose={handleCancelDeleteSession}
                fullScreen={isSmall}
                maxWidth="xs"
                fullWidth
                slotProps={{ paper: { sx: dialogPaperSx } }}
            >
                <DialogTitle sx={dialogTitleSx}>Delete chat?</DialogTitle>
                <DialogContent>
                    <Typography variant="body" sx={{ color: "text.muted" }}>
                        Delete {deleteSessionLabel}? This cannot be undone.
                    </Typography>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 3 }}>
                    <Button
                        onClick={handleCancelDeleteSession}
                        color="secondary"
                    >
                        Cancel
                    </Button>
                    <Button
                        variant="contained"
                        color="critical"
                        onClick={() => void handleConfirmDeleteSession()}
                    >
                        Delete
                    </Button>
                </DialogActions>
            </Dialog>

            {modelSettingsEnabled && (
                <Dialog
                    open={showModelSettings}
                    onClose={closeModelSettings}
                    fullScreen={isSmall}
                    maxWidth="sm"
                    fullWidth
                    slotProps={{ paper: { sx: dialogPaperSx } }}
                >
                    <DialogTitle sx={dialogTitleSx}>Model Settings</DialogTitle>
                    <DialogContent>
                        <Stack sx={{ gap: 3 }}>
                            <Stack sx={{ gap: 0.5 }}>
                                <Typography
                                    variant="small"
                                    sx={{ color: "text.muted" }}
                                >
                                    Selected model
                                </Typography>
                                <Typography variant="body">
                                    {useCustomModel
                                        ? "Custom model"
                                        : defaultModelName}
                                </Typography>
                                <Typography
                                    variant="mini"
                                    sx={{
                                        color: loadedModelName
                                            ? "success.main"
                                            : "text.muted",
                                    }}
                                >
                                    {loadedModelName
                                        ? `Loaded: ${loadedModelName}`
                                        : "Not loaded"}
                                </Typography>
                            </Stack>

                            <Divider />

                            <Stack sx={{ gap: 1.5 }}>
                                <Typography variant="small">
                                    Custom Hugging Face model
                                </Typography>
                                <TextField
                                    fullWidth
                                    label="Direct .gguf file URL"
                                    placeholder="https://huggingface.co/..."
                                    value={modelUrl}
                                    onChange={(event) =>
                                        setModelUrl(event.target.value)
                                    }
                                    error={!!modelUrlError}
                                    helperText={modelUrlError ?? " "}
                                />
                                {allowMmproj && (
                                    <TextField
                                        fullWidth
                                        label="mmproj .gguf file URL"
                                        placeholder="(optional for multimodal)"
                                        value={mmprojUrl}
                                        onChange={(event) =>
                                            setMmprojUrl(event.target.value)
                                        }
                                        error={!!mmprojError}
                                        helperText={mmprojError ?? " "}
                                    />
                                )}
                                <Typography
                                    variant="mini"
                                    sx={{ color: "text.muted" }}
                                >
                                    Suggested models:
                                </Typography>
                                <Stack sx={{ gap: 1 }}>
                                    {suggestedModels.map((model) => (
                                        <Box
                                            key={model.name}
                                            sx={{
                                                border: "1px solid",
                                                borderColor: "divider",
                                                borderRadius: 2,
                                                p: 1.5,
                                            }}
                                        >
                                            <Stack
                                                direction="row"
                                                sx={{
                                                    gap: 1,
                                                    alignItems: "center",
                                                }}
                                            >
                                                <Box sx={{ flex: 1 }}>
                                                    <Typography variant="small">
                                                        {model.name}
                                                    </Typography>
                                                    <Typography
                                                        variant="mini"
                                                        sx={{
                                                            color: "text.muted",
                                                        }}
                                                    >
                                                        {isTauriRuntime &&
                                                        model.mmproj
                                                            ? "+ mmproj"
                                                            : ""}
                                                    </Typography>
                                                </Box>
                                                <Button
                                                    size="small"
                                                    onClick={() =>
                                                        handleFillSuggestion(
                                                            model.url,
                                                            model.mmproj,
                                                        )
                                                    }
                                                >
                                                    Fill
                                                </Button>
                                            </Stack>
                                        </Box>
                                    ))}
                                </Stack>
                            </Stack>

                            <Divider />

                            <Stack sx={{ gap: 1.5 }}>
                                <Typography variant="small">
                                    Custom limits (optional)
                                </Typography>
                                <Stack direction="row" sx={{ gap: 1.5 }}>
                                    <TextField
                                        fullWidth
                                        label="Context length"
                                        placeholder="8192"
                                        value={contextLength}
                                        onChange={(event) =>
                                            setContextLength(event.target.value)
                                        }
                                        error={!!contextError}
                                        helperText={contextError ?? " "}
                                    />
                                    <TextField
                                        fullWidth
                                        label="Max output"
                                        placeholder="2048"
                                        value={maxTokens}
                                        onChange={(event) =>
                                            setMaxTokens(event.target.value)
                                        }
                                        error={!!maxTokensError}
                                        helperText={maxTokensError ?? " "}
                                    />
                                </Stack>
                                <Typography
                                    variant="mini"
                                    sx={{ color: "text.muted" }}
                                >
                                    Leave blank to use model defaults
                                </Typography>
                            </Stack>
                        </Stack>
                    </DialogContent>
                    <DialogActions sx={{ px: 3, pb: 3 }}>
                        <Stack sx={{ width: "100%", gap: 1.5 }}>
                            <Button
                                variant="contained"
                                color="accent"
                                disabled={
                                    isSavingModel ||
                                    modelGateStatus === "downloading"
                                }
                                onClick={handleSaveModel}
                            >
                                Use Custom Model
                            </Button>
                            <Button
                                onClick={handleUseDefaultModel}
                                color="secondary"
                            >
                                Use Default Model
                            </Button>
                            <Typography
                                variant="mini"
                                sx={{
                                    color: "text.muted",
                                    textAlign: "center",
                                }}
                            >
                                Changes require re-downloading the model.
                            </Typography>
                        </Stack>
                    </DialogActions>
                </Dialog>
            )}

            <Notification
                open={syncNotificationOpen}
                onClose={() => setSyncNotificationOpen(false)}
                attributes={syncNotification}
                horizontal={isSmall ? "left" : "right"}
                vertical="bottom"
                sx={{
                    width: "fit-content",
                    maxWidth: "min(360px, 100vw)",
                    backgroundColor: "transparent",
                    boxShadow: "none",
                    bottom: { xs: 96, md: 24 },
                    "& .MuiButtonBase-root": {
                        padding: "4px 8px",
                        borderRadius: "999px",
                        minHeight: 0,
                        bgcolor: "background.paper",
                        color: "text.base",
                        boxShadow: "none",
                    },
                    "& .MuiStack-root": { gap: 1 },
                    "& .MuiStack-root svg": { fontSize: "18px" },
                    "& .MuiTypography-root": {
                        fontSize: "13px",
                        lineHeight: "18px",
                    },
                    "& .MuiIconButton-root": {
                        padding: 0,
                        bgcolor: "transparent",
                    },
                }}
            />

            {developerSettingsEnabled && (
                <DevSettings
                    open={showDevSettings}
                    onClose={closeDevSettings}
                />
            )}
        </>
    ),
);
