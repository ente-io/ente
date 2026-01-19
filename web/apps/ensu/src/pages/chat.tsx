import { HugeiconsIcon } from "@hugeicons/react";
import {
    PlusSignIcon,
    ArrowLeft01Icon,
    ArrowRight01Icon,
    ArrowRight02Icon,
    Attachment01Icon,
    Bug01Icon,
    Cancel01Icon,
    Copy01Icon,
    Delete01Icon,
    Edit01Icon,
    Menu01Icon,
    RefreshIcon,
    RepeatIcon,
    Search01Icon,
    Settings01Icon,
    SlidersHorizontalIcon,
    StopCircleIcon,
} from "@hugeicons/core-free-icons";
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
    LinearProgress,
    List,
    ListItemButton,
    Menu,
    MenuItem,
    Stack,
    TextField,
    Tooltip,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import { AccountsPageTitle } from "ente-accounts/components/layouts/centered-paper";
import { savedLocalUser } from "ente-accounts/services/accounts-db";
import { NavbarBase } from "ente-base/components/Navbar";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { savedLogs } from "ente-base/log-web";
import { savedAuthToken } from "ente-base/token";
import { saveStringAsFile } from "ente-base/utils/web";
import { DevSettings } from "ente-new/photos/components/DevSettings";
import { useFileInput } from "ente-gallery/components/utils/use-file-input";
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
    getBranchSelections,
    listMessages,
    listSessions,
    setBranchSelection,
    type ChatMessage,
    type ChatSession,
} from "services/chat/store";
import {
    buildSelectedPath,
    ROOT_SELECTION_KEY,
    STREAMING_SELECTION_KEY,
    type BranchSwitcher,
} from "services/chat/branching";
import { DEFAULT_MODEL, LlmProvider } from "services/llm/provider";
import type {
    DownloadProgress,
    GenerateEvent,
    LlmMessage,
    ModelSettings,
} from "services/llm/types";
import { masterKeyFromSession } from "services/session";

const formatTime = (timestamp: number) => {
    const date = new Date(Math.floor(timestamp / 1000));
    const hour = date.getHours();
    const minute = date.getMinutes().toString().padStart(2, "0");
    const period = hour >= 12 ? "PM" : "AM";
    const hour12 = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return `${hour12}:${minute} ${period}`;
};

type DocumentAttachment = {
    id: string;
    name: string;
    text: string;
    size: number;
};

const createDocumentBlockRegex = () =>
    /----- BEGIN DOCUMENT: ([^\n]+) -----\n([\s\S]*?)\n----- END DOCUMENT: \1 -----/g;

const createDocumentId = () => {
    if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
        return crypto.randomUUID();
    }
    return `doc_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
};

const parseDocumentBlocks = (text: string) => {
    const normalized = text.replace(/\r\n/g, "\n");
    const regex = createDocumentBlockRegex();
    const documents: DocumentAttachment[] = [];
    let match: RegExpExecArray | null = null;
    while ((match = regex.exec(normalized)) !== null) {
        const name = match[1]?.trim() || "Document";
        const content = match[2] ?? "";
        const size = new TextEncoder().encode(content).length;
        documents.push({
            id: createDocumentId(),
            name,
            text: content,
            size,
        });
    }

    const stripped = normalized
        .replace(createDocumentBlockRegex(), "")
        .replace(/\n{3,}/g, "\n\n")
        .trim();

    return { text: stripped, documents };
};

const buildDocumentBlocks = (documents: DocumentAttachment[]) => {
    if (!documents.length) return "";
    return documents
        .map((doc, index) => {
            const name = doc.name || `Document ${index + 1}`;
            const content = doc.text.trim();
            return `----- BEGIN DOCUMENT: ${name} -----\n${content}\n----- END DOCUMENT: ${name} -----`;
        })
        .join("\n\n");
};

const buildPromptWithDocuments = (
    promptText: string,
    documents: DocumentAttachment[],
) => {
    const blocks = buildDocumentBlocks(documents);
    if (!blocks) return promptText;
    return promptText ? `${promptText}\n\n${blocks}` : blocks;
};

const formatBytes = (bytes: number) => {
    if (!bytes || bytes <= 0) return "0 B";
    const units = ["B", "KB", "MB", "GB", "TB"];
    const idx = Math.min(
        units.length - 1,
        Math.floor(Math.log(bytes) / Math.log(1024)),
    );
    const value = bytes / Math.pow(1024, idx);
    return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[idx]}`;
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

const detectTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

const Page: React.FC = () => {
    const router = useRouter();
    const { logout, showMiniDialog } = useBaseContext();
    const theme = useTheme();
    const isSmall = useMediaQuery(theme.breakpoints.down("md"));
    const sentColor = "text.base";
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
    const smallIconProps = { size: 24, strokeWidth: 2 } as const;
    const actionIconProps = { size: 24, strokeWidth: 2 } as const;
    const compactIconProps = { size: 18, strokeWidth: 2 } as const;

    const [loading, setLoading] = useState(true);
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    const [chatKey, setChatKey] = useState<string | undefined>();
    const [sessions, setSessions] = useState<ChatSession[]>([]);
    const [allMessages, setAllMessages] = useState<ChatMessage[]>([]);
    const [branchSelections, setBranchSelections] = useState<
        Record<string, string>
    >({});
    const [streamingParentId, setStreamingParentId] = useState<string | null>(
        null,
    );
    const [streamingText, setStreamingText] = useState("");
    const [currentSessionId, setCurrentSessionId] = useState<
        string | undefined
    >();
    const [input, setInput] = useState("");
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [drawerCollapsed, setDrawerCollapsed] = useState(false);
    const [drawerView, setDrawerView] = useState<"sessions" | "settings">(
        "sessions",
    );
    const [sessionSearch, setSessionSearch] = useState("");
    const [settingsSearch, setSettingsSearch] = useState("");
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
    const [pendingDocuments, setPendingDocuments] = useState<
        DocumentAttachment[]
    >([]);
    const [attachmentAnchor, setAttachmentAnchor] =
        useState<HTMLElement | null>(null);
    const [isGenerating, setIsGenerating] = useState(false);
    const [isDownloading, setIsDownloading] = useState(false);
    const [downloadStatus, setDownloadStatus] = useState<
        DownloadProgress | null
    >(null);
    const [loadedModelName, setLoadedModelName] = useState<string | null>(null);
    const [isTauriRuntime, setIsTauriRuntime] = useState(false);

    const providerRef = useRef<LlmProvider | null>(null);
    const currentJobIdRef = useRef<number | null>(null);
    const pendingCancelRef = useRef(false);

    const authRefreshCancelledRef = useRef(false);
    const authRetryCancelledRef = useRef(false);

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
        setIsTauriRuntime(detectTauriRuntime());
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

    const handleDownloadProgress = useCallback((progress: DownloadProgress) => {
        setDownloadStatus(progress);
        const status = progress.status?.toLowerCase() ?? "";
        if (progress.percent < 0) {
            setIsDownloading(false);
            return;
        }
        if (progress.percent >= 100 || status.includes("ready")) {
            setIsDownloading(false);
            return;
        }
        setIsDownloading(true);
    }, []);

    useEffect(() => {
        if (typeof window === "undefined") return;
        if (!providerRef.current) {
            providerRef.current = new LlmProvider();
        }
        const unsubscribe = providerRef.current.onDownloadProgress(
            handleDownloadProgress,
        );
        return () => {
            unsubscribe();
        };
    }, [handleDownloadProgress]);

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
            setAllMessages([]);
            return;
        }
        const loaded = await listMessages(currentSessionId, chatKey);
        setAllMessages(loaded);
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

    useEffect(() => {
        setStreamingParentId(null);
        setStreamingText("");
        setIsGenerating(false);
        setPendingDocuments([]);
        currentJobIdRef.current = null;
        pendingCancelRef.current = false;
    }, [currentSessionId]);

    const currentSession = useMemo(
        () => sessions.find((s) => s.sessionUuid === currentSessionId),
        [sessions, currentSessionId],
    );

    useEffect(() => {
        if (!currentSession) {
            setBranchSelections({});
            return;
        }
        setBranchSelections(
            getBranchSelections(currentSession.rootSessionUuid),
        );
    }, [currentSession?.rootSessionUuid]);

    useEffect(() => {
        if (isTauriRuntime) return;
        if (mmprojUrl) {
            setMmprojUrl("");
            setMmprojError(null);
        }
    }, [isTauriRuntime, mmprojUrl]);

    const filteredSessions = useMemo(() => {
        const query = sessionSearch.trim().toLowerCase();
        if (!query) return sessions;
        return sessions.filter((session) => {
            const title = session.title?.toLowerCase() ?? "";
            const preview = session.lastMessagePreview?.toLowerCase() ?? "";
            return title.includes(query) || preview.includes(query);
        });
    }, [sessionSearch, sessions]);

    const groupedSessions = useMemo(
        () => groupSessionsByDate(filteredSessions),
        [filteredSessions],
    );

    const rootSessionUuid = currentSession?.rootSessionUuid ?? currentSessionId;

    const messageState = useMemo(
        () =>
            buildSelectedPath(
                allMessages,
                branchSelections,
                streamingParentId
                    ? { parentMessageUuid: streamingParentId }
                    : undefined,
            ),
        [allMessages, branchSelections, streamingParentId],
    );

    const displayMessages = useMemo(() => {
        const base = messageState.path ?? [];
        if (
            messageState.streamingSelectedParent &&
            streamingParentId === messageState.streamingSelectedParent
        ) {
            const streamingMessage: ChatMessage = {
                messageUuid: STREAMING_SELECTION_KEY,
                sessionUuid: currentSessionId ?? "",
                parentMessageUuid: messageState.streamingSelectedParent,
                sender: "assistant",
                text: streamingText,
                createdAt: Date.now() * 1000,
            };
            return [...base, streamingMessage];
        }
        return base;
    }, [
        messageState.path,
        messageState.streamingSelectedParent,
        streamingParentId,
        streamingText,
        currentSessionId,
    ]);

    const branchSwitchers = messageState.switchers;

    const isDrawerVisible = isSmall ? drawerOpen : !drawerCollapsed;
    const showDrawerToggle = isSmall || drawerCollapsed;
    const drawerWidth = isSmall ? 300 : drawerCollapsed ? 0 : 320;

    const appBarTitle =
        currentSession?.title && currentSession.title !== "New chat"
            ? currentSession.title
            : !isDrawerVisible
              ? "ensu"
              : "";
    const isEnsuTitle = appBarTitle.trim().toLowerCase() === "ensu";

    const ensureProvider = useCallback(async () => {
        if (!providerRef.current) {
            providerRef.current = new LlmProvider();
        }
        await providerRef.current.initialize();
        return providerRef.current;
    }, []);

    const getModelSettings = useCallback((): ModelSettings => {
        return {
            useCustomModel,
            modelUrl: modelUrl.trim() ? modelUrl.trim() : undefined,
            mmprojUrl:
                isTauriRuntime && mmprojUrl.trim()
                    ? mmprojUrl.trim()
                    : undefined,
            contextLength: contextLength ? Number(contextLength) : undefined,
            maxTokens: maxTokens ? Number(maxTokens) : undefined,
        };
    }, [useCustomModel, modelUrl, mmprojUrl, contextLength, maxTokens, isTauriRuntime]);

    const updateBranchSelectionState = useCallback(
        (selectionKey: string, selectedMessageUuid: string, persist = true) => {
            setBranchSelections((prev) => ({
                ...prev,
                [selectionKey]: selectedMessageUuid,
            }));

            if (
                !persist ||
                !rootSessionUuid ||
                selectedMessageUuid === STREAMING_SELECTION_KEY
            ) {
                return;
            }

            setBranchSelection(
                rootSessionUuid,
                selectionKey,
                selectedMessageUuid,
            );
        },
        [rootSessionUuid],
    );

    const slicePathUntil = useCallback(
        (path: ChatMessage[], messageUuid?: string | null) => {
            if (!messageUuid) return path;
            const index = path.findIndex(
                (message) => message.messageUuid === messageUuid,
            );
            if (index === -1) return path;
            return path.slice(0, index + 1);
        },
        [],
    );

    const stripHiddenParts = useCallback((text: string) => {
        return text
            .replace(/<think>[\s\S]*?<\/think>/g, "")
            .replace(/<todo_list>[\s\S]*?<\/todo_list>/g, "")
            .trim();
    }, []);

    const approxTokens = useCallback((text: string) => {
        if (!text) return 0;
        return Math.ceil(text.length / 4);
    }, []);

    const buildHistory = useCallback(
        (
            path: ChatMessage[],
            promptText: string,
            contextSize: number,
            maxTokensCount: number,
            stopAtMessageUuid?: string | null,
        ): LlmMessage[] => {
            const candidates = slicePathUntil(path, stopAtMessageUuid);
            const lastCandidate = candidates[candidates.length - 1];
            const trimmedCandidates =
                stopAtMessageUuid &&
                lastCandidate &&
                lastCandidate.messageUuid === stopAtMessageUuid
                    ? candidates.slice(0, -1)
                    : candidates;

            const safetyMargin = 256;
            let budget = contextSize - maxTokensCount - safetyMargin;
            budget -= approxTokens(promptText);

            if (budget <= 0) return [];

            const selected: LlmMessage[] = [];
            let used = 0;

            for (let idx = trimmedCandidates.length - 1; idx >= 0; idx -= 1) {
                const message = trimmedCandidates[idx];
                if (!message) continue;
                const isUser = message.sender === "self";
                const text = isUser
                    ? message.text
                    : stripHiddenParts(message.text);
                const cost = approxTokens(text);

                if (used + cost > budget) {
                    if (selected.length === 0 && budget > 0) {
                        const charBudget = Math.max(1, budget * 4);
                        const truncated = text.slice(-charBudget);
                        selected.push({
                            role: isUser ? "user" : "assistant",
                            content: truncated,
                        });
                    }
                    break;
                }

                selected.push({
                    role: isUser ? "user" : "assistant",
                    content: text,
                });
                used += cost;
            }

            return selected.reverse();
        },
        [approxTokens, slicePathUntil, stripHiddenParts],
    );

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
        const parsed = parseDocumentBlocks(message.text);
        setEditingMessage(message);
        setInput(parsed.text);
        setPendingDocuments(parsed.documents);
    }, []);

    const handleCancelEdit = useCallback(() => {
        setEditingMessage(null);
        setInput("");
        setPendingDocuments([]);
    }, []);

    const handleCopyMessage = useCallback(async (text: string) => {
        try {
            await navigator.clipboard.writeText(text);
        } catch (error) {
            log.error("Failed to copy message", error);
        }
    }, []);

    const handleStopGeneration = useCallback(() => {
        const provider = providerRef.current;
        const jobId = currentJobIdRef.current;
        if (provider && jobId) {
            provider.cancelGeneration(jobId);
        } else {
            pendingCancelRef.current = true;
        }
    }, []);

    const startGeneration = useCallback(
        async ({
            promptText,
            parentMessageUuid,
            historyPath,
            stopAtMessageUuid,
            resetContext = false,
        }: {
            promptText: string;
            parentMessageUuid: string;
            historyPath: ChatMessage[];
            stopAtMessageUuid?: string | null;
            resetContext?: boolean;
        }) => {
            if (!chatKey || !currentSessionId) return;

            const provider = await ensureProvider();
            const settings = getModelSettings();
            const { contextSize, maxTokens } =
                provider.resolveRuntimeSettings(settings);

            const previousSelection = branchSelections[parentMessageUuid];

            updateBranchSelectionState(
                parentMessageUuid,
                STREAMING_SELECTION_KEY,
                false,
            );
            setStreamingParentId(parentMessageUuid);
            setStreamingText("");
            setIsGenerating(true);
            currentJobIdRef.current = null;
            pendingCancelRef.current = false;

            let buffer = "";
            let errorMessage: string | null = null;

            try {
                await provider.ensureModelReady(settings);
                setLoadedModelName(provider.getCurrentModel()?.name ?? null);
                setIsDownloading(false);
                setDownloadStatus({ percent: 100, status: "Ready" });

                if (resetContext) {
                    await provider.resetContext(contextSize);
                }

                const history =
                    buildHistory(
                        historyPath,
                        promptText,
                        contextSize,
                        maxTokens,
                        stopAtMessageUuid,
                    ) ?? [];

                const messages: LlmMessage[] = [
                    ...history,
                    { role: "user", content: promptText },
                ];

                await provider.generateChatStream(
                    {
                        messages,
                        maxTokens,
                        temperature: 0.7,
                        topP: 0.9,
                    },
                    (event: GenerateEvent) => {
                        if (event.type === "text") {
                            if (!currentJobIdRef.current) {
                                currentJobIdRef.current = event.job_id;
                                if (pendingCancelRef.current) {
                                    provider.cancelGeneration(event.job_id);
                                }
                            }
                            buffer += event.text;
                            setStreamingText(buffer);
                        } else if (event.type === "error") {
                            errorMessage = event.message;
                        } else if (event.type === "done") {
                            currentJobIdRef.current = event.summary.job_id;
                        }
                    },
                );

                if (!buffer.trim()) {
                    if (errorMessage) {
                        showMiniDialog({
                            title: "Generation failed",
                            message: errorMessage,
                        });
                    }
                    if (previousSelection) {
                        updateBranchSelectionState(
                            parentMessageUuid,
                            previousSelection,
                        );
                    }
                    return;
                }

                const assistantUuid = await addMessage(
                    currentSessionId,
                    "assistant",
                    buffer,
                    chatKey,
                    parentMessageUuid,
                );

                updateBranchSelectionState(parentMessageUuid, assistantUuid);

                await refreshSessions();
                await refreshMessages();
            } catch (error) {
                const message =
                    error instanceof Error ? error.message : String(error);
                showMiniDialog({
                    title: "Model error",
                    message,
                });
                if (previousSelection) {
                    updateBranchSelectionState(
                        parentMessageUuid,
                        previousSelection,
                    );
                }
            } finally {
                setIsGenerating(false);
                setIsDownloading(false);
                setStreamingParentId(null);
                setStreamingText("");
                currentJobIdRef.current = null;
                pendingCancelRef.current = false;
            }
        },
        [
            chatKey,
            currentSessionId,
            ensureProvider,
            getModelSettings,
            buildHistory,
            branchSelections,
            updateBranchSelectionState,
            refreshMessages,
            refreshSessions,
            showMiniDialog,
        ],
    );

    const handleRetryMessage = useCallback(
        async (message: ChatMessage) => {
            if (message.sender !== "assistant") return;
            if (!chatKey || !currentSessionId) return;
            if (isDownloading) {
                showMiniDialog({
                    title: "Model download in progress",
                    message: "Please wait for the model to finish downloading.",
                });
                return;
            }
            if (isGenerating) {
                showMiniDialog({
                    title: "Already generating",
                    message: "Please wait for the current response to finish.",
                });
                return;
            }
            const parentUuid = message.parentMessageUuid;
            if (!parentUuid) {
                showMiniDialog({
                    title: "Retry failed",
                    message: "No parent message found for retry.",
                });
                return;
            }
            const parentMessage = allMessages.find(
                (item) => item.messageUuid === parentUuid,
            );
            if (!parentMessage) {
                showMiniDialog({
                    title: "Retry failed",
                    message: "Parent message is missing.",
                });
                return;
            }
            const historyPath = slicePathUntil(messageState.path, parentUuid);
            await startGeneration({
                promptText: parentMessage.text,
                parentMessageUuid: parentUuid,
                historyPath,
                stopAtMessageUuid: parentUuid,
                resetContext: true,
            });
        },
        [
            allMessages,
            chatKey,
            currentSessionId,
            isDownloading,
            isGenerating,
            messageState.path,
            slicePathUntil,
            startGeneration,
            showMiniDialog,
        ],
    );

    const handlePrevBranch = useCallback(
        (switcher: BranchSwitcher) => {
            if (!switcher || switcher.total <= 1) return;
            const nextIndex =
                (switcher.currentIndex - 1 + switcher.total) %
                switcher.total;
            const target = switcher.targets[nextIndex];
            if (!target) return;
            updateBranchSelectionState(switcher.selectionKey, target);
        },
        [updateBranchSelectionState],
    );

    const handleNextBranch = useCallback(
        (switcher: BranchSwitcher) => {
            if (!switcher || switcher.total <= 1) return;
            const nextIndex = (switcher.currentIndex + 1) % switcher.total;
            const target = switcher.targets[nextIndex];
            if (!target) return;
            updateBranchSelectionState(switcher.selectionKey, target);
        },
        [updateBranchSelectionState],
    );

    const openSettingsPage = useCallback(
        () => setDrawerView("settings"),
        [],
    );
    const closeSettingsPage = useCallback(
        () => setDrawerView("sessions"),
        [],
    );

    const handleOpenDrawer = useCallback(() => {
        if (isSmall) {
            setDrawerOpen(true);
            return;
        }
        setDrawerCollapsed(false);
    }, [isSmall]);

    const handleCloseDrawer = useCallback(() => {
        if (isSmall) {
            setDrawerOpen(false);
        } else {
            setDrawerCollapsed(true);
        }
        setDrawerView("sessions");
    }, [isSmall]);

    const handleCollapseDrawer = useCallback(() => {
        handleCloseDrawer();
    }, [handleCloseDrawer]);

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
                name: "LFM 2.5 VL 1.6B (Q4_0)",
                url: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
                mmproj: "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf",
            },
            {
                name: "LFM 2.5 1.2B Instruct (Q4_0)",
                url: "https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/LFM2.5-1.2B-Instruct-Q4_0.gguf",
            },
            {
                name: "Qwen3-VL 2B Instruct (Q4_K_M)",
                url: "https://huggingface.co/Qwen/Qwen3-VL-2B-Instruct-GGUF/resolve/main/Qwen3VL-2B-Instruct-Q4_K_M.gguf",
                mmproj: "https://huggingface.co/Qwen/Qwen3-VL-2B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf",
            },
            {
                name: "Llama 3.2 1B Instruct (Q4_K_M)",
                url: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
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
        const mmprojError = isTauriRuntime ? validateUrl(mmprojUrl) : undefined;

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
    }, [contextLength, maxTokens, mmprojUrl, modelUrl, isTauriRuntime]);

    const handleSaveModel = useCallback(() => {
        if (!validateModelSettings()) return;
        setIsSavingModel(true);
        const payload = {
            useCustomModel: true,
            modelUrl,
            mmprojUrl: isTauriRuntime ? mmprojUrl : "",
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
        setLoadedModelName(null);
        setIsSavingModel(false);
        setShowModelSettings(false);
    }, [
        contextLength,
        maxTokens,
        mmprojUrl,
        modelUrl,
        validateModelSettings,
        isTauriRuntime,
    ]);

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
        setLoadedModelName(null);
        setShowModelSettings(false);
    }, []);

    const handleFillSuggestion = useCallback(
        (url: string, mmproj?: string) => {
            setModelUrl(url);
            setMmprojUrl(isTauriRuntime ? mmproj ?? "" : "");
            setModelUrlError(null);
            setMmprojError(null);
        },
        [isTauriRuntime],
    );

    const openAttachmentMenu = useCallback(
        (event: React.MouseEvent<HTMLElement>) => {
            setAttachmentAnchor(event.currentTarget);
        },
        [],
    );

    const closeAttachmentMenu = useCallback(() => {
        setAttachmentAnchor(null);
    }, []);

    const handleDocumentSelect = useCallback(
        (files: File[]) => {
            closeAttachmentMenu();
            void (async () => {
                const results = await Promise.allSettled(
                    files.map(async (file) => ({
                        id: createDocumentId(),
                        name: file.name,
                        text: await file.text(),
                        size: file.size,
                    })),
                );

                const successful = results
                    .filter(
                        (result): result is PromiseFulfilledResult<DocumentAttachment> =>
                            result.status === "fulfilled",
                    )
                    .map((result) => result.value);

                if (successful.length) {
                    setPendingDocuments((prev) => [...prev, ...successful]);
                }

                const failed = results.length - successful.length;
                if (failed > 0) {
                    showMiniDialog({
                        title: "Some documents failed",
                        message:
                            "We could not read some documents. Please try again.",
                    });
                }
            })();
        },
        [closeAttachmentMenu, showMiniDialog],
    );

    const handleDocumentCancel = useCallback(() => {
        closeAttachmentMenu();
    }, [closeAttachmentMenu]);

    const {
        getInputProps: getDocumentInputProps,
        openSelector: openDocumentSelector,
    } = useFileInput({
        directory: false,
        onSelect: handleDocumentSelect,
        onCancel: handleDocumentCancel,
    });

    const handleAttachmentChoice = useCallback(
        (choice: "image" | "document") => {
            if (choice === "image") {
                showMiniDialog({
                    title: "Images not supported",
                    message:
                        "Image attachments are not supported in Ensu web yet.",
                });
            } else {
                closeAttachmentMenu();
                openDocumentSelector();
            }
        },
        [closeAttachmentMenu, openDocumentSelector, showMiniDialog],
    );

    const removePendingDocument = useCallback((id: string) => {
        setPendingDocuments((prev) => prev.filter((doc) => doc.id !== id));
    }, []);

    const handleLogout = useCallback(
        () =>
            showMiniDialog({
                title: "Sign out",
                message: "Are you sure you want to sign out?",
                continue: {
                    text: "Sign out",
                    color: "critical",
                    action: logout,
                },
                buttonDirection: "row",
            }),
        [logout, showMiniDialog],
    );

    const openLoginFromChat = useCallback(() => {
        void router.push("/login");
    }, [router]);

    const handleSend = useCallback(async () => {
        const trimmed = input.trim();
        const hasDocuments = pendingDocuments.length > 0;
        if ((!trimmed && !hasDocuments) || !chatKey || !currentSessionId) {
            return;
        }
        if (isDownloading) {
            showMiniDialog({
                title: "Model download in progress",
                message: "Please wait for the model to finish downloading.",
            });
            return;
        }
        if (isGenerating) {
            showMiniDialog({
                title: "Already generating",
                message: "Please wait for the current response to finish.",
            });
            return;
        }

        const messageText = buildPromptWithDocuments(
            trimmed,
            pendingDocuments,
        );

        setInput("");

        try {
            if (editingMessage) {
                const parentUuid = editingMessage.parentMessageUuid;
                const selectionKey = parentUuid ?? ROOT_SELECTION_KEY;
                const historyPath = parentUuid
                    ? slicePathUntil(messageState.path, parentUuid)
                    : [];

                const newUserUuid = await addMessage(
                    currentSessionId,
                    "self",
                    messageText,
                    chatKey,
                    parentUuid,
                );

                updateBranchSelectionState(selectionKey, newUserUuid);
                setEditingMessage(null);
                setPendingDocuments([]);

                await refreshMessages();

                await startGeneration({
                    promptText: messageText,
                    parentMessageUuid: newUserUuid,
                    historyPath,
                });
                return;
            }

            const basePath = messageState.path;
            const leaf = basePath[basePath.length - 1];
            const parentUuid = leaf?.messageUuid;
            const selectionKey = parentUuid ?? ROOT_SELECTION_KEY;

            const userUuid = await addMessage(
                currentSessionId,
                "self",
                messageText,
                chatKey,
                parentUuid,
            );

            updateBranchSelectionState(selectionKey, userUuid);
            setPendingDocuments([]);

            await refreshMessages();

            await startGeneration({
                promptText: messageText,
                parentMessageUuid: userUuid,
                historyPath: basePath,
            });
        } catch (error) {
            log.error("Failed to store chat message", error);
        }

        await refreshSessions();
    }, [
        input,
        chatKey,
        currentSessionId,
        editingMessage,
        isDownloading,
        isGenerating,
        messageState.path,
        pendingDocuments,
        refreshMessages,
        refreshSessions,
        showMiniDialog,
        slicePathUntil,
        startGeneration,
        updateBranchSelectionState,
    ]);

    const settingsItems = useMemo(
        () => [
            {
                key: "model",
                label: "Model settings",
                icon: Settings01Icon,
                onClick: openModelSettings,
            },
            {
                key: "developer",
                label: "Developer settings",
                icon: SlidersHorizontalIcon,
                onClick: openDevSettings,
            },
            {
                key: "logs",
                label: "Log viewer",
                icon: Bug01Icon,
                onClick: confirmViewLogs,
            },
        ],
        [confirmViewLogs, openDevSettings, openModelSettings],
    );

    const filteredSettingsItems = useMemo(() => {
        const query = settingsSearch.trim().toLowerCase();
        if (!query) return settingsItems;
        return settingsItems.filter((item) =>
            item.label.toLowerCase().includes(query),
        );
    }, [settingsItems, settingsSearch]);

    const sidebar = (
        <Stack
            sx={{ width: "100%", height: "100%", bgcolor: "background.paper" }}
        >
            <Box sx={{ px: 2.5, pt: 2.5, pb: 2 }}>
                <Stack direction="row" sx={{ gap: 1, alignItems: "flex-start" }}>
                    <Stack sx={{ flex: 1, gap: 1 }}>
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
                        {isLoggedIn && (
                            <Box
                                sx={{
                                    px: 1.5,
                                    py: 0.75,
                                    borderRadius: 1,
                                    bgcolor: "fill.faint",
                                }}
                            >
                                <Typography
                                    variant="mini"
                                    sx={{ color: "text.muted" }}
                                >
                                    {savedLocalUser()?.email ?? ""}
                                </Typography>
                            </Box>
                        )}
                    </Stack>
                    <Stack direction="row" sx={{ gap: 0.5 }}>
                        <IconButton
                            aria-label={
                                drawerView === "settings"
                                    ? "Close settings"
                                    : "Open settings"
                            }
                            sx={drawerIconButtonSx}
                            onClick={
                                drawerView === "settings"
                                    ? closeSettingsPage
                                    : openSettingsPage
                            }
                        >
                            <HugeiconsIcon
                                icon={
                                    drawerView === "settings"
                                        ? Cancel01Icon
                                        : Settings01Icon
                                }
                                {...compactIconProps}
                            />
                        </IconButton>
                        <IconButton
                            aria-label={
                                drawerCollapsed
                                    ? "Expand drawer"
                                    : "Collapse drawer"
                            }
                            sx={drawerIconButtonSx}
                            onClick={
                                drawerCollapsed
                                    ? handleOpenDrawer
                                    : handleCollapseDrawer
                            }
                        >
                            <HugeiconsIcon
                                icon={
                                    drawerCollapsed
                                        ? ArrowRight01Icon
                                        : ArrowLeft01Icon
                                }
                                {...smallIconProps}
                            />
                        </IconButton>
                    </Stack>
                </Stack>
            </Box>

            <Divider />

            {drawerView === "settings" ? (
                <List
                    sx={{
                        flex: 1,
                        overflowY: "auto",
                        px: 1,
                        overscrollBehaviorY: "contain",
                    }}
                >
                    <Box sx={{ pt: 1 }}>
                        <Box
                            sx={{
                                display: "flex",
                                alignItems: "center",
                                gap: 1,
                                px: 1.5,
                                py: 1,
                                borderRadius: 2,
                                bgcolor: "fill.faint",
                            }}
                        >
                            <HugeiconsIcon
                                icon={Search01Icon}
                                {...compactIconProps}
                            />
                            <InputBase
                                placeholder="Search settings"
                                value={settingsSearch}
                                onChange={(event) =>
                                    setSettingsSearch(event.target.value)
                                }
                                sx={{
                                    flex: 1,
                                    color: "text.base",
                                    fontFamily:
                                        '"Source Serif 4", serif',
                                    fontSize: "14px",
                                }}
                            />
                        </Box>
                    </Box>
                    <Typography
                        variant="mini"
                        sx={{
                            px: 1,
                            pt: 2,
                            pb: 1,
                            letterSpacing: "0.12em",
                            color: "text.muted",
                        }}
                    >
                        SETTINGS
                    </Typography>
                    {filteredSettingsItems.map((item) => (
                        <ListItemButton
                            key={item.key}
                            onClick={item.onClick}
                            sx={{
                                alignItems: "center",
                                gap: 1,
                                py: 1.25,
                                borderRadius: 2,
                                my: 0.5,
                                "&:hover": {
                                    backgroundColor: "fill.faintHover",
                                },
                            }}
                        >
                            <HugeiconsIcon
                                icon={item.icon}
                                {...compactIconProps}
                            />
                            <Typography variant="small">
                                {item.label}
                            </Typography>
                        </ListItemButton>
                    ))}
                </List>
            ) : (
                <>
                    <List
                        sx={{
                            flex: 1,
                            overflowY: "auto",
                            px: 1,
                            overscrollBehaviorY: "contain",
                        }}
                    >
                        <Box sx={{ pt: 1 }}>
                            <Box
                                sx={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 1,
                                    px: 1.5,
                                    py: 1,
                                    borderRadius: 2,
                                    bgcolor: "fill.faint",
                                }}
                            >
                                <HugeiconsIcon
                                    icon={Search01Icon}
                                    {...compactIconProps}
                                />
                                <InputBase
                                    placeholder="Search chats"
                                    value={sessionSearch}
                                    onChange={(event) =>
                                        setSessionSearch(event.target.value)
                                    }
                                    sx={{
                                        flex: 1,
                                        color: "text.base",
                                        fontFamily:
                                            '"Source Serif 4", serif',
                                        fontSize: "14px",
                                    }}
                                />
                            </Box>
                        </Box>
                        <Stack
                            direction="row"
                            sx={{ alignItems: "center", gap: 1, my: 1 }}
                        >
                            <ListItemButton
                                onClick={handleNewChat}
                                sx={{
                                    flex: 1,
                                    alignItems: "center",
                                    gap: 1,
                                    py: 1.25,
                                    borderRadius: 2,
                                    "&:hover": {
                                        backgroundColor: "fill.faintHover",
                                    },
                                }}
                            >
                                <HugeiconsIcon
                                    icon={PlusSignIcon}
                                    {...compactIconProps}
                                />
                                <Typography variant="small">New Chat</Typography>
                            </ListItemButton>
                            <Tooltip title="Sync">
                                <IconButton
                                    aria-label="Sync"
                                    onClick={() => {
                                        if (isLoggedIn) {
                                            void refreshSessions();
                                        } else {
                                            openLoginFromChat();
                                        }
                                    }}
                                    sx={actionButtonSx}
                                >
                                    <HugeiconsIcon
                                        icon={RefreshIcon}
                                        {...actionIconProps}
                                    />
                                </IconButton>
                            </Tooltip>
                        </Stack>

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
                                            session.sessionUuid ===
                                            currentSessionId
                                        }
                                        onClick={() =>
                                            handleSelectSession(
                                                session.sessionUuid,
                                            )
                                        }
                                        sx={{
                                            alignItems: "flex-start",
                                            py: 1.5,
                                            borderRadius: 2,
                                            my: 0.5,
                                            "&:hover": {
                                                backgroundColor:
                                                    "fill.faintHover",
                                            },
                                            "&.Mui-selected": {
                                                backgroundColor: "fill.faint",
                                            },
                                            "&.Mui-selected:hover": {
                                                backgroundColor:
                                                    "fill.faintHover",
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
                                                        WebkitBoxOrient:
                                                            "vertical",
                                                        overflow: "hidden",
                                                    }}
                                                >
                                                    {session.lastMessagePreview ??
                                                        ""}
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
                                                <HugeiconsIcon
                                                    icon={Delete01Icon}
                                                    {...actionIconProps}
                                                />
                                            </IconButton>
                                        </Stack>
                                    </ListItemButton>
                                ))}
                            </Box>
                        ))}
                    </List>

                    {!drawerCollapsed && (
                        <>
                            <Divider />
                            <Stack sx={{ p: 1 }}>
                                <ListItemButton
                                    onClick={
                                        isLoggedIn
                                            ? handleLogout
                                            : openLoginFromChat
                                    }
                                    sx={{
                                        alignItems: "center",
                                        gap: 1,
                                        px: 1.5,
                                        py: 1,
                                        width: "100%",
                                        borderRadius: 2,
                                        "&:hover": {
                                            backgroundColor:
                                                "fill.faintHover",
                                        },
                                    }}
                                >
                                    <Typography
                                        variant="small"
                                        sx={{ flex: 1 }}
                                    >
                                        {isLoggedIn
                                            ? "Sign out"
                                            : "Sign in to backup"}
                                    </Typography>
                                    <HugeiconsIcon
                                        icon={ArrowRight01Icon}
                                        {...smallIconProps}
                                    />
                                </ListItemButton>
                            </Stack>
                        </>
                    )}
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
                    onClose={handleCloseDrawer}
                    ModalProps={isSmall ? { keepMounted: true } : undefined}
                    sx={{
                        flexShrink: 0,
                        "& .MuiDrawer-paper": {
                            width: drawerWidth,
                            boxSizing: "border-box",
                            position: isSmall ? "fixed" : "relative",
                            overflowX: "hidden",
                            pointerEvents:
                                isSmall || !drawerCollapsed ? "auto" : "none",
                        },
                    }}
                    slotProps={{
                        paper: {
                            sx: {
                                backgroundColor: "background.paper",
                                borderRightColor: drawerCollapsed
                                    ? "transparent"
                                    : "divider",
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
                            {showDrawerToggle && (
                                <IconButton
                                    aria-label="Open menu"
                                    onClick={handleOpenDrawer}
                                    sx={drawerIconButtonSx}
                                >
                                    <HugeiconsIcon icon={Menu01Icon} {...smallIconProps} />
                                </IconButton>
                            )}
                            <Stack
                                sx={{ gap: !isDrawerVisible ? 0.25 : 0 }}
                            >
                                {!isDrawerVisible && !isEnsuTitle && (
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
                        {!isLoggedIn && !isDrawerVisible && (
                            <Button
                                onClick={openLoginFromChat}
                                color="inherit"
                                variant="text"
                                sx={{
                                    textTransform: "none",
                                    fontWeight: 600,
                                    color: "text.base",
                                }}
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
                        {displayMessages.length === 0 ? (
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
                                {displayMessages.map((message) => {
                                    const isSelf = message.sender === "self";
                                    const isStreaming =
                                        message.messageUuid ===
                                        STREAMING_SELECTION_KEY;
                                    const switcher =
                                        branchSwitchers[message.messageUuid];
                                    const showSwitcher =
                                        !!switcher && switcher.total > 1;
                                    const timestamp = formatTime(
                                        message.createdAt,
                                    );
                                    const parsedDocuments = isSelf
                                        ? parseDocumentBlocks(message.text)
                                        : { text: message.text, documents: [] };
                                    const documentCount =
                                        parsedDocuments.documents.length;
                                    const displayText = isSelf
                                        ? parsedDocuments.text ||
                                          (documentCount > 0
                                              ? "Attached documents"
                                              : "")
                                        : message.text;
                                    const copyText = isSelf
                                        ? displayText
                                        : stripHiddenParts(message.text);
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
                                                    {displayText}
                                                </Typography>

                                                {isSelf && documentCount > 0 && (
                                                    <Typography
                                                        variant="mini"
                                                        sx={{
                                                            mt: 0.5,
                                                            color: "text.muted",
                                                        }}
                                                    >
                                                        {documentCount} document
                                                        {documentCount === 1
                                                            ? ""
                                                            : "s"} attached
                                                    </Typography>
                                                )}

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
                                                    {isStreaming ? null : isSelf ? (
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
                                                                <HugeiconsIcon icon={Edit01Icon} {...actionIconProps} />
                                                            </IconButton>
                                                            <IconButton
                                                                aria-label="Copy"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={() =>
                                                                    void handleCopyMessage(
                                                                        copyText,
                                                                    )
                                                                }
                                                            >
                                                                <HugeiconsIcon icon={Copy01Icon} {...actionIconProps} />
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
                                                                        copyText,
                                                                    )
                                                                }
                                                            >
                                                                <HugeiconsIcon icon={Copy01Icon} {...actionIconProps} />
                                                            </IconButton>
                                                            <IconButton
                                                                aria-label="Retry"
                                                                sx={
                                                                    actionButtonSx
                                                                }
                                                                onClick={() =>
                                                                    handleRetryMessage(
                                                                        message,
                                                                    )
                                                                }
                                                            >
                                                                <HugeiconsIcon icon={RepeatIcon} {...actionIconProps} />
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
                                                            {showSwitcher && (
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
                                                                        onClick={() =>
                                                                            switcher &&
                                                                            handlePrevBranch(
                                                                                switcher,
                                                                            )
                                                                        }
                                                                    >
                                                                        <HugeiconsIcon icon={ArrowLeft01Icon} {...smallIconProps} />
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
                                                                        {switcher
                                                                            ? switcher.currentIndex +
                                                                              1
                                                                            : 1}
                                                                        /
                                                                        {switcher
                                                                            ? switcher.total
                                                                            : 1}
                                                                    </Typography>
                                                                    <IconButton
                                                                        aria-label="Next branch"
                                                                        sx={
                                                                            actionButtonSx
                                                                        }
                                                                        onClick={() =>
                                                                            switcher &&
                                                                            handleNextBranch(
                                                                                switcher,
                                                                            )
                                                                        }
                                                                    >
                                                                        <HugeiconsIcon icon={ArrowRight01Icon} {...smallIconProps} />
                                                                    </IconButton>
                                                                </Stack>
                                                            )}
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
                                                            {showSwitcher && (
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
                                                                        onClick={() =>
                                                                            switcher &&
                                                                            handlePrevBranch(
                                                                                switcher,
                                                                            )
                                                                        }
                                                                    >
                                                                        <HugeiconsIcon icon={ArrowLeft01Icon} {...smallIconProps} />
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
                                                                        {switcher
                                                                            ? switcher.currentIndex +
                                                                              1
                                                                            : 1}
                                                                        /
                                                                        {switcher
                                                                            ? switcher.total
                                                                            : 1}
                                                                    </Typography>
                                                                    <IconButton
                                                                        aria-label="Next branch"
                                                                        sx={
                                                                            actionButtonSx
                                                                        }
                                                                        onClick={() =>
                                                                            switcher &&
                                                                            handleNextBranch(
                                                                                switcher,
                                                                            )
                                                                        }
                                                                    >
                                                                        <HugeiconsIcon icon={ArrowRight01Icon} {...smallIconProps} />
                                                                    </IconButton>
                                                                </Stack>
                                                            )}
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
                                        py: 0.5,
                                        borderRadius: 2,
                                        bgcolor: "fill.faint",
                                        borderLeft: "3px solid",
                                        borderLeftColor: "accent.main",
                                    }}
                                >
                                    <HugeiconsIcon icon={Edit01Icon} {...compactIconProps} />
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
                                        <HugeiconsIcon icon={Cancel01Icon} {...smallIconProps} />
                                    </IconButton>
                                </Box>
                            )}

                            {downloadStatus?.status &&
                                downloadStatus.status !== "Ready" && (
                                    <Stack sx={{ gap: 0.5 }}>
                                        <Typography
                                            variant="mini"
                                            sx={{ color: "text.muted" }}
                                        >
                                            {downloadStatus.status}
                                        </Typography>
                                        {downloadStatus.percent >= 0 &&
                                            downloadStatus.percent < 100 && (
                                                <LinearProgress
                                                    variant={
                                                        downloadStatus.totalBytes
                                                            ? "determinate"
                                                            : "indeterminate"
                                                    }
                                                    value={
                                                        downloadStatus.totalBytes
                                                            ? downloadStatus.percent
                                                            : undefined
                                                    }
                                                />
                                            )}
                                    </Stack>
                                )}

                            {pendingDocuments.length > 0 && (
                                <Stack sx={{ gap: 0.5 }}>
                                    <Typography
                                        variant="mini"
                                        sx={{ color: "text.muted" }}
                                    >
                                        Documents
                                    </Typography>
                                    <Stack sx={{ gap: 0.5 }}>
                                        {pendingDocuments.map((doc) => (
                                            <Box
                                                key={doc.id}
                                                sx={{
                                                    display: "flex",
                                                    alignItems: "center",
                                                    gap: 1,
                                                    px: 1.5,
                                                    py: 0.75,
                                                    borderRadius: 1.5,
                                                    bgcolor: "fill.faint",
                                                }}
                                            >
                                                <Typography
                                                    variant="mini"
                                                    sx={{
                                                        flex: 1,
                                                        color: "text.base",
                                                        overflow: "hidden",
                                                        textOverflow:
                                                            "ellipsis",
                                                        whiteSpace: "nowrap",
                                                    }}
                                                >
                                                    {doc.name}
                                                </Typography>
                                                <Typography
                                                    variant="mini"
                                                    sx={{ color: "text.muted" }}
                                                >
                                                    {formatBytes(doc.size)}
                                                </Typography>
                                                <IconButton
                                                    aria-label="Remove document"
                                                    sx={actionButtonSx}
                                                    onClick={() =>
                                                        removePendingDocument(
                                                            doc.id,
                                                        )
                                                    }
                                                >
                                                    <HugeiconsIcon
                                                        icon={Cancel01Icon}
                                                        {...smallIconProps}
                                                    />
                                                </IconButton>
                                            </Box>
                                        ))}
                                    </Stack>
                                </Stack>
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
                                            ? "Downloading model..."
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
                                    <HugeiconsIcon icon={Attachment01Icon} {...actionIconProps} />
                                </IconButton>
                                <IconButton
                                    aria-label={
                                        isGenerating ? "Stop" : "Send message"
                                    }
                                    onClick={
                                        isGenerating
                                            ? handleStopGeneration
                                            : () => void handleSend()
                                    }
                                    disabled={
                                        isDownloading ||
                                        (!isGenerating &&
                                            !input.trim() &&
                                            pendingDocuments.length === 0)
                                    }
                                    sx={{
                                        width: 44,
                                        height: 44,
                                        borderRadius: 2,
                                        bgcolor: "fill.faint",
                                        color: isGenerating
                                            ? "critical.main"
                                            : "text.muted",
                                        "&:hover": {
                                            bgcolor: "fill.faintHover",
                                        },
                                        "&.Mui-disabled": {
                                            color: "text.faint",
                                        },
                                    }}
                                >
                                    {isGenerating ? (
                                        <HugeiconsIcon icon={StopCircleIcon} {...actionIconProps} />
                                    ) : (
                                        <HugeiconsIcon icon={ArrowRight02Icon} {...actionIconProps} />
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
                                    : DEFAULT_MODEL.name}
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
                            {isTauriRuntime && (
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
                                                    sx={{ color: "text.muted" }}
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

            <input {...getDocumentInputProps()} />

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
