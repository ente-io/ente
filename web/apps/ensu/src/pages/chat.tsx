import {
    AddRounded,
    AttachFileOutlined,
    BugReportOutlined,
    ChevronLeftRounded,
    ChevronRightRounded,
    CloseRounded,
    CodeOutlined,
    ContentCopyOutlined,
    DeleteOutline,
    EditOutlined,
    MenuRounded,
    ReplayRounded,
    SendRounded,
    SettingsOutlined,
    StopCircleOutlined,
    SyncRounded,
    TuneRounded,
} from "@mui/icons-material";
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    Drawer,
    IconButton,
    InputBase,
    List,
    ListItemButton,
    Menu,
    MenuItem,
    Stack,
    TextField,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import { AccountsPageTitle } from "ente-accounts/components/layouts/centered-paper";
import { savedLocalUser } from "ente-accounts/services/accounts-db";
import { LinkButton } from "ente-base/components/LinkButton";
import { NavbarBase } from "ente-base/components/Navbar";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { savedLogs } from "ente-base/log-web";
import { savedAuthToken } from "ente-base/token";
import { saveStringAsFile } from "ente-base/utils/web";
import { DevSettings } from "ente-new/photos/components/DevSettings";
import { useRouter } from "next/router";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    getOrCreateChatKey,
    getOrCreateLocalChatKey,
} from "services/chat/chatKey";
import {
    addMessage,
    createSession,
    deleteSession,
    listMessages,
    listSessions,
    updateMessage,
    type ChatMessage,
    type ChatSession,
} from "services/chat/store";
import { masterKeyFromSession } from "services/session";

const formatTime = (timestamp: number) => {
    const date = new Date(Math.floor(timestamp / 1000));
    const hour = date.getHours();
    const minute = date.getMinutes().toString().padStart(2, "0");
    const period = hour >= 12 ? "PM" : "AM";
    const hour12 = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return `${hour12}:${minute} ${period}`;
};

type SessionGroupLabel =
    | "TODAY"
    | "YESTERDAY"
    | "THIS WEEK"
    | "LAST WEEK"
    | "THIS MONTH"
    | "OLDER";

const groupSessionsByDate = (sessions: ChatSession[]) => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const thisWeekStart = new Date(today);
    thisWeekStart.setDate(
        thisWeekStart.getDate() - (thisWeekStart.getDay() || 7) + 1,
    );

    const lastWeekStart = new Date(thisWeekStart);
    lastWeekStart.setDate(lastWeekStart.getDate() - 7);

    const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const grouped: Record<SessionGroupLabel, ChatSession[]> = {
        TODAY: [],
        YESTERDAY: [],
        "THIS WEEK": [],
        "LAST WEEK": [],
        "THIS MONTH": [],
        OLDER: [],
    };

    sessions.forEach((session) => {
        const sessionDate = new Date(Math.floor(session.updatedAt / 1000));
        const sessionDay = new Date(
            sessionDate.getFullYear(),
            sessionDate.getMonth(),
            sessionDate.getDate(),
        );

        let category: SessionGroupLabel = "OLDER";

        if (sessionDay >= today) {
            category = "TODAY";
        } else if (sessionDay.getTime() === yesterday.getTime()) {
            category = "YESTERDAY";
        } else if (sessionDay >= thisWeekStart) {
            category = "THIS WEEK";
        } else if (sessionDay >= lastWeekStart) {
            category = "LAST WEEK";
        } else if (sessionDay >= thisMonthStart) {
            category = "THIS MONTH";
        }

        grouped[category].push(session);
    });

    return (
        Object.entries(grouped) as [SessionGroupLabel, ChatSession[]][]
    ).filter(([, group]) => group.length > 0);
};

const Page: React.FC = () => {
    const router = useRouter();
    const { logout, showMiniDialog } = useBaseContext();
    const theme = useTheme();
    const isSmall = useMediaQuery(theme.breakpoints.down("md"));
    const sentColor = "text.base";
    const drawerGradient =
        theme.palette.mode === "dark"
            ? "linear-gradient(180deg, rgba(255 215 0 / 0.12) 0%, rgba(20 20 20 / 0) 100%)"
            : "linear-gradient(180deg, rgba(154 126 10 / 0.18) 0%, rgba(248 245 240 / 0) 100%)";
    const actionButtonSx = {
        width: 36,
        height: 36,
        borderRadius: 1,
        color: "text.muted",
        "&:hover": { bgcolor: "fill.faint", color: "text.base" },
    } as const;
    const drawerIconButtonSx = {
        width: 40,
        height: 40,
        borderRadius: 2,
        bgcolor: "transparent",
        color: "text.base",
        "&:hover": { bgcolor: "fill.faint" },
    } as const;

    const [loading, setLoading] = useState(true);
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    const [chatKey, setChatKey] = useState<string | undefined>();
    const [sessions, setSessions] = useState<ChatSession[]>([]);
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [currentSessionId, setCurrentSessionId] = useState<
        string | undefined
    >();
    const [input, setInput] = useState("");
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [showDevSettings, setShowDevSettings] = useState(false);
    const [showModelSettings, setShowModelSettings] = useState(false);
    const [useCustomModel, setUseCustomModel] = useState(false);
    const [modelUrl, setModelUrl] = useState("");
    const [mmprojUrl, setMmprojUrl] = useState("");
    const [contextLength, setContextLength] = useState("");
    const [maxTokens, setMaxTokens] = useState("");
    const [modelUrlError, setModelUrlError] = useState<string | null>(null);
    const [mmprojError, setMmprojError] = useState<string | null>(null);
    const [contextError, setContextError] = useState<string | null>(null);
    const [maxTokensError, setMaxTokensError] = useState<string | null>(null);
    const [isSavingModel, setIsSavingModel] = useState(false);
    const [editingMessage, setEditingMessage] = useState<ChatMessage | null>(
        null,
    );
    const [attachmentAnchor, setAttachmentAnchor] =
        useState<HTMLElement | null>(null);

    const authRefreshCancelledRef = useRef(false);
    const authRetryCancelledRef = useRef(false);

    const [isGenerating] = useState(false);
    const [isDownloading] = useState(false);
    const branchInfo = { current: 1, total: 2 };

    const sessionFromQuery = useMemo(() => {
        if (!router.isReady) return undefined;
        const value = router.query.session;
        if (Array.isArray(value)) return value[0];
        return typeof value === "string" ? value : undefined;
    }, [router.isReady, router.query.session]);

    const updateRouteSession = useCallback(
        (sessionId: string | undefined, replace = false) => {
            if (!router.isReady) return;
            const query = sessionId ? { session: sessionId } : {};
            const method = replace ? router.replace : router.push;
            void method({ pathname: "/chat", query }, undefined, {
                shallow: true,
            });
        },
        [router],
    );

    const refreshAuthState = useCallback(async () => {
        const token = await savedAuthToken();
        setIsLoggedIn(!!token);

        if (token) {
            const masterKey = await masterKeyFromSession();
            if (masterKey) {
                setChatKey(await getOrCreateChatKey(masterKey));
                return;
            }
        }

        setChatKey(await getOrCreateLocalChatKey());
    }, []);

    useEffect(() => {
        authRefreshCancelledRef.current = false;

        void (async () => {
            await refreshAuthState();
            if (!authRefreshCancelledRef.current) setLoading(false);
        })();

        return () => {
            authRefreshCancelledRef.current = true;
        };
    }, [refreshAuthState]);

    useEffect(() => {
        if (typeof window === "undefined") return;

        const handleFocus = () => {
            void refreshAuthState();
        };

        const handleVisibility = () => {
            if (!document.hidden) {
                void refreshAuthState();
            }
        };

        window.addEventListener("focus", handleFocus);
        document.addEventListener("visibilitychange", handleVisibility);

        return () => {
            window.removeEventListener("focus", handleFocus);
            document.removeEventListener("visibilitychange", handleVisibility);
        };
    }, [refreshAuthState]);

    useEffect(() => {
        if (typeof window === "undefined" || isLoggedIn) return;

        authRetryCancelledRef.current = false;
        let attempts = 0;
        let timeoutId: number | undefined;

        const retry = async () => {
            if (authRetryCancelledRef.current) return;
            const token = await savedAuthToken();
            if (token) {
                await refreshAuthState();
                return;
            }

            attempts += 1;
            if (attempts < 5) {
                timeoutId = window.setTimeout(retry, 400);
            }
        };

        timeoutId = window.setTimeout(retry, 400);

        return () => {
            authRetryCancelledRef.current = true;
            if (timeoutId) window.clearTimeout(timeoutId);
        };
    }, [isLoggedIn, refreshAuthState]);

    useEffect(() => {
        if (typeof window === "undefined") return;

        const html = document.documentElement;
        const body = document.body;
        const previous = {
            htmlOverflow: html.style.overflow,
            htmlOverscroll: html.style.overscrollBehavior,
            htmlHeight: html.style.height,
            bodyOverflow: body.style.overflow,
            bodyOverscroll: body.style.overscrollBehavior,
            bodyHeight: body.style.height,
        };

        html.style.overflow = "hidden";
        html.style.overscrollBehavior = "none";
        html.style.height = "100%";
        body.style.overflow = "hidden";
        body.style.overscrollBehavior = "none";
        body.style.height = "100%";

        return () => {
            html.style.overflow = previous.htmlOverflow;
            html.style.overscrollBehavior = previous.htmlOverscroll;
            html.style.height = previous.htmlHeight;
            body.style.overflow = previous.bodyOverflow;
            body.style.overscrollBehavior = previous.bodyOverscroll;
            body.style.height = previous.bodyHeight;
        };
    }, []);

    useEffect(() => {
        if (typeof window === "undefined") return;
        const raw = window.localStorage.getItem("ensu.modelSettings");
        if (!raw) return;
        try {
            const parsed = JSON.parse(raw) as {
                useCustomModel?: boolean;
                modelUrl?: string;
                mmprojUrl?: string;
                contextLength?: string;
                maxTokens?: string;
            };
            setUseCustomModel(!!parsed.useCustomModel);
            setModelUrl(parsed.modelUrl ?? "");
            setMmprojUrl(parsed.mmprojUrl ?? "");
            setContextLength(parsed.contextLength ?? "");
            setMaxTokens(parsed.maxTokens ?? "");
        } catch (error) {
            log.error("Failed to read model settings", error);
        }
    }, []);

    const refreshSessions = useCallback(async () => {
        if (!chatKey) return;
        const loaded = await listSessions(chatKey);
        if (loaded.length === 0) {
            const sessionId = await createSession(chatKey);
            const refreshed = await listSessions(chatKey);
            setSessions(refreshed);
            setCurrentSessionId(sessionId);
            updateRouteSession(sessionId, true);
            return;
        }

        setSessions(loaded);

        const hasQuerySession =
            sessionFromQuery &&
            loaded.some((session) => session.sessionUuid === sessionFromQuery);
        const nextSessionId = hasQuerySession
            ? sessionFromQuery
            : (currentSessionId ?? loaded[0]?.sessionUuid);

        if (nextSessionId) {
            setCurrentSessionId(nextSessionId);
            if (nextSessionId !== sessionFromQuery) {
                updateRouteSession(nextSessionId, true);
            }
        }
    }, [chatKey, currentSessionId, sessionFromQuery, updateRouteSession]);

    const refreshMessages = useCallback(async () => {
        if (!chatKey || !currentSessionId) {
            setMessages([]);
            return;
        }
        const loaded = await listMessages(currentSessionId, chatKey);
        setMessages(loaded);
    }, [chatKey, currentSessionId]);

    useEffect(() => {
        void refreshSessions();
    }, [refreshSessions]);

    useEffect(() => {
        void refreshMessages();
    }, [refreshMessages]);

    useEffect(() => {
        if (!sessionFromQuery || sessions.length === 0) return;
        if (
            sessionFromQuery !== currentSessionId &&
            sessions.some((session) => session.sessionUuid === sessionFromQuery)
        ) {
            setCurrentSessionId(sessionFromQuery);
        }
    }, [currentSessionId, sessionFromQuery, sessions]);

    const currentSession = useMemo(
        () => sessions.find((s) => s.sessionUuid === currentSessionId),
        [sessions, currentSessionId],
    );

    const groupedSessions = useMemo(
        () => groupSessionsByDate(sessions),
        [sessions],
    );

    const appBarTitle =
        currentSession?.title && currentSession.title !== "New chat"
            ? currentSession.title
            : isSmall && !drawerOpen
              ? "ensu"
              : "";
    const isEnsuTitle = appBarTitle.trim().toLowerCase() === "ensu";

    const handleNewChat = useCallback(async () => {
        if (!chatKey) return;
        const sessionId = await createSession(chatKey);
        await refreshSessions();
        setCurrentSessionId(sessionId);
        updateRouteSession(sessionId);
        if (isSmall) setDrawerOpen(false);
    }, [chatKey, refreshSessions, isSmall, updateRouteSession]);

    const handleSelectSession = useCallback(
        (sessionId: string) => {
            setCurrentSessionId(sessionId);
            updateRouteSession(sessionId);
            if (isSmall) setDrawerOpen(false);
        },
        [isSmall, updateRouteSession],
    );

    const handleDeleteSession = useCallback(
        async (sessionId: string) => {
            if (!chatKey) return;
            deleteSession(sessionId);
            await refreshSessions();
            if (sessionId === currentSessionId) {
                const refreshed = await listSessions(chatKey);
                const nextSession = refreshed[0];
                if (nextSession) {
                    setCurrentSessionId(nextSession.sessionUuid);
                    updateRouteSession(nextSession.sessionUuid, true);
                } else {
                    const newSessionId = await createSession(chatKey);
                    setCurrentSessionId(newSessionId);
                    updateRouteSession(newSessionId, true);
                }
            }
        },
        [chatKey, currentSessionId, refreshSessions, updateRouteSession],
    );

    const handleEditMessage = useCallback((message: ChatMessage) => {
        setEditingMessage(message);
        setInput(message.text);
    }, []);

    const handleCancelEdit = useCallback(() => {
        setEditingMessage(null);
        setInput("");
    }, []);

    const handleCopyMessage = useCallback(async (text: string) => {
        try {
            await navigator.clipboard.writeText(text);
        } catch (error) {
            log.error("Failed to copy message", error);
        }
    }, []);

    const handleRawMessage = useCallback(() => {
        log.info("Raw message view is not available yet.");
    }, []);

    const handleRetryMessage = useCallback(() => {
        log.info("Retry is not available yet.");
    }, []);

    const handlePrevBranch = useCallback(() => {
        log.info("Branch switching is not available yet.");
    }, []);

    const handleNextBranch = useCallback(() => {
        log.info("Branch switching is not available yet.");
    }, []);

    const openDevSettings = useCallback(() => setShowDevSettings(true), []);
    const closeDevSettings = useCallback(() => setShowDevSettings(false), []);

    const viewLogs = useCallback(async () => {
        log.info("Viewing logs");
        const electron = globalThis.electron;
        if (electron) {
            await electron.openLogDirectory();
        } else {
            saveStringAsFile(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
        }
    }, []);

    const confirmViewLogs = useCallback(
        () =>
            showMiniDialog({
                title: "View logs",
                message:
                    "This will download the debug logs that you can share with support.",
                continue: { text: "View logs", action: viewLogs },
            }),
        [showMiniDialog, viewLogs],
    );

    const openModelSettings = useCallback(() => setShowModelSettings(true), []);
    const closeModelSettings = useCallback(
        () => setShowModelSettings(false),
        [],
    );

    const suggestedModels = useMemo(
        () => [
            {
                name: "Qwen3-VL 2B Instruct (Q4_K_M)",
                url: "https://huggingface.co/ensu/placeholder/Qwen3-VL-2B-Instruct.Q4_K_M.gguf",
                mmproj: "https://huggingface.co/ensu/placeholder/Qwen3-VL-2B-Instruct.mmproj.gguf",
            },
            {
                name: "LFM 2.5 1.2B Instruct (Q4_0)",
                url: "https://huggingface.co/ensu/placeholder/LFM-2.5-1.2B-Instruct.Q4_0.gguf",
            },
            {
                name: "LFM 2.5 VL 1.6B (Q4_0)",
                url: "https://huggingface.co/ensu/placeholder/LFM-2.5-VL-1.6B.Q4_0.gguf",
                mmproj: "https://huggingface.co/ensu/placeholder/LFM-2.5-VL-1.6B.mmproj.gguf",
            },
            {
                name: "Llama 3.2 1B Instruct (Q4_K_M)",
                url: "https://huggingface.co/ensu/placeholder/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
            },
        ],
        [],
    );

    const validateModelSettings = useCallback(() => {
        const validateUrl = (value: string) => {
            if (!value) return undefined;
            try {
                const url = new URL(value);
                if (!url.hostname.includes("huggingface.co")) {
                    return "URL must be a huggingface.co link";
                }
                if (!url.pathname.endsWith(".gguf")) {
                    return "URL must end with .gguf";
                }
                return undefined;
            } catch {
                return "Enter a valid URL";
            }
        };

        const modelError = modelUrl ? validateUrl(modelUrl) : "Required";
        const mmprojError = validateUrl(mmprojUrl);

        const contextErrorValue =
            contextLength && !/^\d+$/.test(contextLength)
                ? "Enter a number"
                : undefined;
        const maxTokensErrorValue =
            maxTokens && !/^\d+$/.test(maxTokens)
                ? "Enter a number"
                : undefined;

        const contextValue = contextLength ? Number(contextLength) : undefined;
        const maxTokensValue = maxTokens ? Number(maxTokens) : undefined;

        const maxTokensLimitError =
            contextValue && maxTokensValue && maxTokensValue > contextValue
                ? "Must be <= context length"
                : undefined;

        setModelUrlError(modelError ?? null);
        setMmprojError(mmprojError ?? null);
        setContextError(contextErrorValue ?? null);
        setMaxTokensError(maxTokensErrorValue ?? maxTokensLimitError ?? null);

        return !(
            modelError ||
            mmprojError ||
            contextErrorValue ||
            maxTokensErrorValue ||
            maxTokensLimitError
        );
    }, [contextLength, maxTokens, mmprojUrl, modelUrl]);

    const handleSaveModel = useCallback(() => {
        if (!validateModelSettings()) return;
        setIsSavingModel(true);
        const payload = {
            useCustomModel: true,
            modelUrl,
            mmprojUrl,
            contextLength,
            maxTokens,
        };
        if (typeof window !== "undefined") {
            window.localStorage.setItem(
                "ensu.modelSettings",
                JSON.stringify(payload),
            );
        }
        setUseCustomModel(true);
        setIsSavingModel(false);
        setShowModelSettings(false);
    }, [contextLength, maxTokens, mmprojUrl, modelUrl, validateModelSettings]);

    const handleUseDefaultModel = useCallback(() => {
        if (typeof window !== "undefined") {
            window.localStorage.removeItem("ensu.modelSettings");
        }
        setUseCustomModel(false);
        setModelUrl("");
        setMmprojUrl("");
        setContextLength("");
        setMaxTokens("");
        setModelUrlError(null);
        setMmprojError(null);
        setContextError(null);
        setMaxTokensError(null);
        setShowModelSettings(false);
    }, []);

    const handleFillSuggestion = useCallback((url: string, mmproj?: string) => {
        setModelUrl(url);
        setMmprojUrl(mmproj ?? "");
        setModelUrlError(null);
        setMmprojError(null);
    }, []);

    const openAttachmentMenu = useCallback(
        (event: React.MouseEvent<HTMLElement>) => {
            setAttachmentAnchor(event.currentTarget);
        },
        [],
    );

    const closeAttachmentMenu = useCallback(() => {
        setAttachmentAnchor(null);
    }, []);

    const handleAttachmentChoice = useCallback(
        (choice: "image" | "document") => {
            log.info("Attachment choice", choice);
            closeAttachmentMenu();
        },
        [closeAttachmentMenu],
    );

    const openLoginFromChat = useCallback(() => {
        if (typeof window !== "undefined") {
            window.sessionStorage.setItem("ensu.openLogin", "1");
        }
        void router.push("/");
    }, [router]);

    const handleSend = useCallback(async () => {
        const trimmed = input.trim();
        if (!trimmed || !chatKey || !currentSessionId) return;

        setInput("");

        try {
            if (editingMessage) {
                await updateMessage(
                    editingMessage.messageUuid,
                    trimmed,
                    chatKey,
                );
                setEditingMessage(null);
            } else {
                await addMessage(currentSessionId, "self", trimmed, chatKey);
                await addMessage(
                    currentSessionId,
                    "assistant",
                    "Assistant responses are not available on web yet.",
                    chatKey,
                );
            }
        } catch (error) {
            log.error("Failed to store chat message", error);
        }

        await refreshSessions();
        await refreshMessages();
    }, [
        input,
        chatKey,
        currentSessionId,
        editingMessage,
        refreshMessages,
        refreshSessions,
    ]);

    const sidebar = (
        <Stack
            sx={{ width: "100%", height: "100%", bgcolor: "background.paper" }}
        >
            <Box sx={{ px: 2.5, py: 3, background: drawerGradient }}>
                <Typography
                    variant="h2"
                    sx={{
                        fontFamily: '"Cormorant Garamond", serif',
                        fontWeight: 600,
                        letterSpacing: "1px",
                        textTransform: "lowercase",
                    }}
                >
                    ensu
                </Typography>
                <Stack
                    direction="row"
                    sx={{ gap: 1, mt: 1, alignItems: "center" }}
                >
                    <Stack direction="row" sx={{ gap: 1 }}>
                        <IconButton
                            aria-label="Logs"
                            sx={drawerIconButtonSx}
                            onClick={confirmViewLogs}
                        >
                            <BugReportOutlined fontSize="small" />
                        </IconButton>
                        <IconButton
                            aria-label="Developer settings"
                            sx={drawerIconButtonSx}
                            onClick={openDevSettings}
                        >
                            <TuneRounded fontSize="small" />
                        </IconButton>
                        <IconButton
                            aria-label="Model settings"
                            sx={drawerIconButtonSx}
                            onClick={openModelSettings}
                        >
                            <SettingsOutlined fontSize="small" />
                        </IconButton>
                    </Stack>
                    <Box sx={{ flex: 1 }} />
                    <Button
                        variant="text"
                        color="inherit"
                        onClick={() =>
                            isLoggedIn
                                ? void refreshSessions()
                                : openLoginFromChat()
                        }
                        sx={{
                            minWidth: "auto",
                            px: 1,
                            py: 0.25,
                            textTransform: "none",
                            gap: 0.5,
                            color: "text.muted",
                            bgcolor: "transparent",
                            borderRadius: 2,
                            "&:hover": { bgcolor: "fill.faint" },
                        }}
                        startIcon={<SyncRounded fontSize="small" />}
                    >
                        Sync
                    </Button>
                </Stack>
                {isLoggedIn && (
                    <Box
                        sx={{
                            mt: 1.5,
                            px: 1.5,
                            py: 0.75,
                            borderRadius: 2,
                            bgcolor: "fill.faint",
                        }}
                    >
                        <Typography variant="mini" sx={{ color: "text.muted" }}>
                            {savedLocalUser()?.email ?? ""}
                        </Typography>
                    </Box>
                )}
            </Box>

            <Divider />

            <List
                sx={{
                    flex: 1,
                    overflowY: "auto",
                    px: 1,
                    overscrollBehaviorY: "contain",
                }}
            >
                <ListItemButton
                    onClick={handleNewChat}
                    sx={{
                        alignItems: "center",
                        gap: 1,
                        py: 1.25,
                        borderRadius: 2,
                        my: 1,
                        "&:hover": { backgroundColor: "fill.faintHover" },
                    }}
                >
                    <AddRounded fontSize="small" />
                    <Typography variant="small">New Chat</Typography>
                </ListItemButton>

                {groupedSessions.map(([label, group]) => (
                    <Box key={label} sx={{ pb: 1 }}>
                        <Typography
                            variant="mini"
                            sx={{
                                px: 1,
                                pt: 2,
                                pb: 0.5,
                                letterSpacing: "0.12em",
                                color: "text.muted",
                            }}
                        >
                            {label}
                        </Typography>
                        {group.map((session) => (
                            <ListItemButton
                                key={session.sessionUuid}
                                selected={
                                    session.sessionUuid === currentSessionId
                                }
                                onClick={() =>
                                    handleSelectSession(session.sessionUuid)
                                }
                                sx={{
                                    alignItems: "flex-start",
                                    py: 1.5,
                                    borderRadius: 2,
                                    my: 0.5,
                                    "&:hover": {
                                        backgroundColor: "fill.faintHover",
                                    },
                                    "&.Mui-selected": {
                                        backgroundColor: "fill.faint",
                                    },
                                    "&.Mui-selected:hover": {
                                        backgroundColor: "fill.faintHover",
                                    },
                                }}
                            >
                                <Stack
                                    direction="row"
                                    sx={{
                                        width: "100%",
                                        alignItems: "flex-start",
                                        gap: 1,
                                    }}
                                >
                                    <Box sx={{ flex: 1, minWidth: 0 }}>
                                        <Typography
                                            variant="small"
                                            sx={{
                                                fontWeight: 600,
                                                fontFamily:
                                                    '"Source Serif 4", serif',
                                            }}
                                        >
                                            {session.title}
                                        </Typography>
                                        <Typography
                                            variant="mini"
                                            sx={{
                                                color: "text.muted",
                                                fontFamily:
                                                    '"Source Serif 4", serif',
                                                display: "-webkit-box",
                                                WebkitLineClamp: 1,
                                                WebkitBoxOrient: "vertical",
                                                overflow: "hidden",
                                            }}
                                        >
                                            {session.lastMessagePreview ?? ""}
                                        </Typography>
                                    </Box>
                                    <IconButton
                                        aria-label="Delete chat"
                                        sx={actionButtonSx}
                                        onClick={(event) => {
                                            event.stopPropagation();
                                            void handleDeleteSession(
                                                session.sessionUuid,
                                            );
                                        }}
                                    >
                                        <DeleteOutline fontSize="small" />
                                    </IconButton>
                                </Stack>
                            </ListItemButton>
                        ))}
                    </Box>
                ))}
            </List>

            {isLoggedIn && (
                <>
                    <Divider />
                    <Stack sx={{ p: 2 }}>
                        <LinkButton onClick={logout}>Sign out</LinkButton>
                    </Stack>
                </>
            )}
        </Stack>
    );

    if (loading) return <></>;

    return (
        <>
            <Box
                sx={{
                    display: "flex",
                    height: "100svh",
                    bgcolor: "background.default",
                }}
            >
                <Drawer
                    variant={isSmall ? "temporary" : "permanent"}
                    open={isSmall ? drawerOpen : true}
                    onClose={() => setDrawerOpen(false)}
                    ModalProps={isSmall ? { keepMounted: true } : undefined}
                    sx={{
                        flexShrink: 0,
                        "& .MuiDrawer-paper": {
                            width: { xs: 300, md: 320 },
                            boxSizing: "border-box",
                            position: isSmall ? "fixed" : "relative",
                        },
                    }}
                    slotProps={{
                        paper: {
                            sx: {
                                backgroundColor: "background.paper",
                                borderRightColor: "divider",
                            },
                        },
                    }}
                >
                    {sidebar}
                </Drawer>

                <Box
                    sx={{
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        height: "100%",
                    }}
                >
                    <NavbarBase
                        sx={{
                            justifyContent: "space-between",
                            px: 2,
                            bgcolor: "background.paper",
                        }}
                    >
                        <Stack
                            direction="row"
                            sx={{ gap: 1.5, alignItems: "center" }}
                        >
                            {isSmall && (
                                <IconButton
                                    aria-label="Open menu"
                                    onClick={() => setDrawerOpen(true)}
                                    sx={drawerIconButtonSx}
                                >
                                    <MenuRounded fontSize="small" />
                                </IconButton>
                            )}
                            <Stack
                                sx={{ gap: isSmall && !drawerOpen ? 0.25 : 0 }}
                            >
                                {isSmall && !drawerOpen && !isEnsuTitle && (
                                    <Typography
                                        variant="mini"
                                        sx={{
                                            color: "text.muted",
                                            letterSpacing: "0.12em",
                                            textTransform: "lowercase",
                                        }}
                                    >
                                        ensu
                                    </Typography>
                                )}
                                {appBarTitle && (
                                    <AccountsPageTitle>
                                        {appBarTitle}
                                    </AccountsPageTitle>
                                )}
                            </Stack>
                        </Stack>
                        {!isLoggedIn && (
                            <Button
                                onClick={openLoginFromChat}
                                color="accent"
                                variant="text"
                                sx={{ textTransform: "none", fontWeight: 600 }}
                            >
                                Sign In
                            </Button>
                        )}
                    </NavbarBase>

                    <Box
                        sx={{
                            flex: 1,
                            overflowY: "auto",
                            px: { xs: 2, md: 4 },
                            py: 3,
                            bgcolor: "background.default",
                            overscrollBehaviorY: "contain",
                        }}
                    >
                        {messages.length === 0 ? (
                            <Stack
                                sx={{
                                    gap: 2,
                                    height: "100%",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    textAlign: "center",
                                }}
                            >
                                <Typography
                                    variant="small"
                                    sx={{ color: "text.muted" }}
                                >
                                    Start typing to begin a conversation.
                                </Typography>
                            </Stack>
                        ) : (
                            <Stack sx={{ gap: 3 }}>
                                {messages.map((message) => {
                                    const isSelf = message.sender === "self";
                                    const timestamp = formatTime(
                                        message.createdAt,
                                    );
                                    return (
                                        <Box
                                            key={message.messageUuid}
                                            sx={{
                                                display: "flex",
                                                justifyContent: isSelf
                                                    ? "flex-end"
                                                    : "flex-start",
                                                pl: isSelf
                                                    ? { xs: 6, md: 10 }
                                                    : 0,
                                                pr: isSelf
                                                    ? 0
                                                    : { xs: 6, md: 10 },
                                            }}
                                        >
                                            <Stack
                                                sx={{
                                                    maxWidth: "min(720px, 85%)",
                                                    alignItems: isSelf
                                                        ? "flex-end"
                                                        : "flex-start",
                                                }}
                                            >
                                                <Typography
                                                    variant="message"
                                                    sx={{
                                                        color: isSelf
                                                            ? sentColor
                                                            : "text.base",
                                                        textAlign: isSelf
                                                            ? "right"
                                                            : "left",
                                                        whiteSpace: "pre-wrap",
                                                    }}
                                                >
                                                    {message.text}
                                                </Typography>

                                                <Stack
                                                    direction="row"
                                                    sx={{
                                                        mt: 1,
                                                        gap: 0.5,
                                                        alignSelf: isSelf
                                                            ? "flex-end"
                                                            : "flex-start",
                                                    }}
                                                >
                                                    {isSelf ? (
                                                        <>
                                                            <IconButton
                                                                aria-label="Edit"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={() =>
                                                                    handleEditMessage(
                                                                        message,
                                                                    )
                                                                }
                                                            >
                                                                <EditOutlined fontSize="small" />
                                                            </IconButton>
                                                            <IconButton
                                                                aria-label="Copy"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={() =>
                                                                    void handleCopyMessage(
                                                                        message.text,
                                                                    )
                                                                }
                                                            >
                                                                <ContentCopyOutlined fontSize="small" />
                                                            </IconButton>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <IconButton
                                                                aria-label="Copy"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={() =>
                                                                    void handleCopyMessage(
                                                                        message.text,
                                                                    )
                                                                }
                                                            >
                                                                <ContentCopyOutlined fontSize="small" />
                                                            </IconButton>
                                                            <IconButton
                                                                aria-label="Raw"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={
                                                                    handleRawMessage
                                                                }
                                                            >
                                                                <CodeOutlined fontSize="small" />
                                                            </IconButton>
                                                            <IconButton
                                                                aria-label="Retry"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={
                                                                    handleRetryMessage
                                                                }
                                                            >
                                                                <ReplayRounded fontSize="small" />
                                                            </IconButton>
                                                        </>
                                                    )}
                                                </Stack>

                                                <Stack
                                                    direction="row"
                                                    sx={{
                                                        mt: 0.5,
                                                        width: "100%",
                                                        alignItems: "center",
                                                        gap: 0.75,
                                                    }}
                                                >
                                                    {isSelf ? (
                                                        <>
                                                            <Box
                                                                sx={{ flex: 1 }}
                                                            />
                                                            <Stack
                                                                direction="row"
                                                                sx={{
                                                                    alignItems:
                                                                        "center",
                                                                    gap: 0.25,
                                                                }}
                                                            >
                                                                <IconButton
                                                                    aria-label="Previous branch"
                                                                    sx={
                                                                        actionButtonSx
                                                                    }
                                                                    onClick={
                                                                        handlePrevBranch
                                                                    }
                                                                >
                                                                    <ChevronLeftRounded fontSize="small" />
                                                                </IconButton>
                                                                <Typography
                                                                    variant="small"
                                                                    sx={{
                                                                        color: "text.muted",
                                                                        fontVariantNumeric:
                                                                            "tabular-nums",
                                                                        minWidth: 40,
                                                                        textAlign:
                                                                            "center",
                                                                    }}
                                                                >
                                                                    {
                                                                        branchInfo.current
                                                                    }
                                                                    /
                                                                    {
                                                                        branchInfo.total
                                                                    }
                                                                </Typography>
                                                                <IconButton
                                                                    aria-label="Next branch"
                                                                    sx={
                                                                        actionButtonSx
                                                                    }
                                                                    onClick={
                                                                        handleNextBranch
                                                                    }
                                                                >
                                                                    <ChevronRightRounded fontSize="small" />
                                                                </IconButton>
                                                            </Stack>
                                                            <Typography
                                                                variant="mini"
                                                                sx={{
                                                                    color: "text.muted",
                                                                    fontVariantNumeric:
                                                                        "tabular-nums",
                                                                }}
                                                            >
                                                                {timestamp}
                                                            </Typography>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <Typography
                                                                variant="mini"
                                                                sx={{
                                                                    color: "text.muted",
                                                                    fontVariantNumeric:
                                                                        "tabular-nums",
                                                                }}
                                                            >
                                                                {timestamp}
                                                            </Typography>
                                                            <Stack
                                                                direction="row"
                                                                sx={{
                                                                    alignItems:
                                                                        "center",
                                                                    gap: 0.25,
                                                                    ml: 0.75,
                                                                }}
                                                            >
                                                                <IconButton
                                                                    aria-label="Previous branch"
                                                                    sx={
                                                                        actionButtonSx
                                                                    }
                                                                    onClick={
                                                                        handlePrevBranch
                                                                    }
                                                                >
                                                                    <ChevronLeftRounded fontSize="small" />
                                                                </IconButton>
                                                                <Typography
                                                                    variant="small"
                                                                    sx={{
                                                                        color: "text.muted",
                                                                        fontVariantNumeric:
                                                                            "tabular-nums",
                                                                        minWidth: 40,
                                                                        textAlign:
                                                                            "center",
                                                                    }}
                                                                >
                                                                    {
                                                                        branchInfo.current
                                                                    }
                                                                    /
                                                                    {
                                                                        branchInfo.total
                                                                    }
                                                                </Typography>
                                                                <IconButton
                                                                    aria-label="Next branch"
                                                                    sx={
                                                                        actionButtonSx
                                                                    }
                                                                    onClick={
                                                                        handleNextBranch
                                                                    }
                                                                >
                                                                    <ChevronRightRounded fontSize="small" />
                                                                </IconButton>
                                                            </Stack>
                                                            <Box
                                                                sx={{ flex: 1 }}
                                                            />
                                                        </>
                                                    )}
                                                </Stack>
                                            </Stack>
                                        </Box>
                                    );
                                })}
                            </Stack>
                        )}
                    </Box>

                    <Box
                        sx={{
                            borderTop: "1px solid",
                            borderColor: "divider",
                            bgcolor: "background.paper",
                        }}
                    >
                        <Stack sx={{ px: 2, py: 2, gap: 1 }}>
                            {editingMessage && (
                                <Box
                                    sx={{
                                        display: "flex",
                                        alignItems: "center",
                                        gap: 1,
                                        px: 1.5,
                                        py: 1,
                                        borderRadius: 2,
                                        bgcolor: "fill.faint",
                                        borderLeft: "3px solid",
                                        borderLeftColor: "accent.main",
                                    }}
                                >
                                    <EditOutlined fontSize="small" />
                                    <Typography
                                        variant="mini"
                                        sx={{ color: "text.muted" }}
                                    >
                                        Editing:
                                    </Typography>
                                    <Typography
                                        variant="mini"
                                        sx={{
                                            color: "text.base",
                                            flex: 1,
                                            overflow: "hidden",
                                            textOverflow: "ellipsis",
                                            whiteSpace: "nowrap",
                                        }}
                                    >
                                        {editingMessage.text}
                                    </Typography>
                                    <IconButton
                                        aria-label="Cancel edit"
                                        sx={actionButtonSx}
                                        onClick={handleCancelEdit}
                                    >
                                        <CloseRounded fontSize="small" />
                                    </IconButton>
                                </Box>
                            )}

                            <Stack
                                direction="row"
                                sx={{ gap: 1, alignItems: "center" }}
                            >
                                <InputBase
                                    multiline
                                    maxRows={5}
                                    placeholder={
                                        isDownloading
                                            ? "Downloading model... (queue messages)"
                                            : "Compose your message..."
                                    }
                                    value={input}
                                    onChange={(event) =>
                                        setInput(event.target.value)
                                    }
                                    onKeyDown={(event) => {
                                        if (
                                            event.key === "Enter" &&
                                            !event.shiftKey
                                        ) {
                                            event.preventDefault();
                                            void handleSend();
                                        }
                                    }}
                                    sx={{
                                        flex: 1,
                                        bgcolor: "fill.faint",
                                        borderRadius: 2,
                                        px: 2,
                                        py: 2,
                                        minHeight: 52,
                                        display: "flex",
                                        alignItems: "center",
                                        fontFamily: '"Source Serif 4", serif',
                                        fontSize: "15px",
                                        lineHeight: 1.7,
                                        color: "text.base",
                                        "& textarea": { padding: 0, margin: 0 },
                                    }}
                                />
                                <IconButton
                                    aria-label="Add attachment"
                                    sx={drawerIconButtonSx}
                                    disabled={isGenerating || isDownloading}
                                    onClick={openAttachmentMenu}
                                >
                                    <AttachFileOutlined fontSize="small" />
                                </IconButton>
                                <IconButton
                                    aria-label={
                                        isGenerating ? "Stop" : "Send message"
                                    }
                                    onClick={() => void handleSend()}
                                    disabled={isDownloading || !input.trim()}
                                    sx={{
                                        width: 44,
                                        height: 44,
                                        borderRadius: 2,
                                        bgcolor: "fill.faint",
                                        color: "text.muted",
                                        "&:hover": {
                                            bgcolor: "fill.faintHover",
                                        },
                                        "&.Mui-disabled": {
                                            color: "text.faint",
                                        },
                                    }}
                                >
                                    {isGenerating ? (
                                        <StopCircleOutlined
                                            fontSize="small"
                                            sx={{ color: "critical.main" }}
                                        />
                                    ) : (
                                        <SendRounded fontSize="small" />
                                    )}
                                </IconButton>
                            </Stack>
                        </Stack>
                    </Box>
                </Box>
            </Box>

            <Dialog
                open={showModelSettings}
                onClose={closeModelSettings}
                fullScreen={isSmall}
                maxWidth="sm"
                fullWidth
            >
                <DialogTitle>Model Settings</DialogTitle>
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
                                    : "Default model"}
                            </Typography>
                            <Typography
                                variant="mini"
                                sx={{
                                    color: useCustomModel
                                        ? "success.main"
                                        : "text.muted",
                                }}
                            >
                                {useCustomModel ? "Loaded" : "Not loaded"}
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
                                                    sx={{ color: "text.muted" }}
                                                >
                                                    {model.mmproj
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
                            disabled={isSavingModel}
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
                            sx={{ color: "text.muted", textAlign: "center" }}
                        >
                            Changes require re-downloading the model.
                        </Typography>
                    </Stack>
                </DialogActions>
            </Dialog>

            <Menu
                anchorEl={attachmentAnchor}
                open={Boolean(attachmentAnchor)}
                onClose={closeAttachmentMenu}
                anchorOrigin={{ vertical: "top", horizontal: "right" }}
                transformOrigin={{ vertical: "bottom", horizontal: "right" }}
            >
                <MenuItem onClick={() => handleAttachmentChoice("image")}>
                    Image
                </MenuItem>
                <MenuItem onClick={() => handleAttachmentChoice("document")}>
                    Document
                </MenuItem>
            </Menu>

            <DevSettings open={showDevSettings} onClose={closeDevSettings} />
        </>
    );
};

export default Page;
