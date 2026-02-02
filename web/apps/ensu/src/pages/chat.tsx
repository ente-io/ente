import { HugeiconsIcon } from "@hugeicons/react";
import {
    PlusSignIcon,
    ArrowLeft01Icon,
    ArrowRight01Icon,
    ArrowReloadHorizontalIcon,
    Attachment01Icon,
    Bug01Icon,
    Cancel01Icon,
    Copy01Icon,
    Delete01Icon,
    Edit01Icon,
    Login01Icon,
    Menu01Icon,
    Navigation06Icon,
    RepeatIcon,
    Search01Icon,
    Settings01Icon,
    SlidersHorizontalIcon,
    Upload01Icon,
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
import { getLuminance, useTheme } from "@mui/material/styles";
import { save } from "@tauri-apps/api/dialog";
import { writeTextFile } from "@tauri-apps/api/fs";
import { savedLocalUser } from "ente-accounts/services/accounts-db";
import { NavbarBase } from "ente-base/components/Navbar";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { savedLogs } from "ente-base/log-web";
import { savedAuthToken } from "ente-base/token";
import {
    saveAsFileAndRevokeObjectURL,
    saveStringAsFile,
} from "ente-base/utils/web";
import { DevSettings } from "ente-new/photos/components/DevSettings";
import {
    Notification,
    type NotificationAttributes,
} from "ente-new/photos/components/Notification";
import { useFileInput } from "ente-gallery/components/utils/use-file-input";
import { useRouter } from "next/router";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { MarkdownRenderer } from "components/MarkdownRenderer";
import {
    cachedChatKey,
    cachedLocalChatKey,
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
    readDecryptedAttachmentBytes,
    sessionTitleFromText,
    setBranchSelection,
    storeEncryptedAttachmentBytes,
    updateSessionTitle,
    type ChatAttachment,
    type ChatMessage,
    type ChatSession,
} from "services/chat/store";
import { downloadAttachment, syncChat, ChatSyncLimitError } from "services/chat/sync";
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
import {
    DESKTOP_IMAGE_ATTACHMENTS_ENABLED,
    DEVELOPER_SETTINGS_ENABLED,
    SIGN_IN_ENABLED,
} from "services/featureFlags";

const formatTime = (timestamp: number) => {
    const date = new Date(Math.floor(timestamp / 1000));
    const hour = date.getHours();
    const minute = date.getMinutes().toString().padStart(2, "0");
    const period = hour >= 12 ? "PM" : "AM";
    const hour12 = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return `${hour12}:${minute} ${period}`;
};

const loadingPhraseVerbs = [
    "Generating",
    "Thinking through",
    "Assembling",
    "Drafting",
    "Composing",
    "Crunching",
    "Exploring",
    "Piecing together",
    "Reviewing",
    "Organizing",
    "Synthesizing",
    "Sketching",
    "Refining",
    "Shaping",
];

const loadingPhraseTargets = [
    "your reply",
    "an answer",
    "ideas",
    "context",
    "details",
    "the response",
    "the next steps",
    "a solution",
    "the summary",
    "insights",
    "the draft",
    "the explanation",
];

const randomLoadingPhrase = () => {
    const verb =
        loadingPhraseVerbs[
            Math.floor(Math.random() * loadingPhraseVerbs.length)
        ] ?? "Generating";
    const target =
        loadingPhraseTargets[
            Math.floor(Math.random() * loadingPhraseTargets.length)
        ] ?? "your reply";
    return `${verb} ${target}`;
};

const MEDIA_MARKER = "<__media__>";
const IMAGE_TOKEN_ESTIMATE = 768;
const MAX_INFERENCE_IMAGE_DIMENSION = 384;
const INFERENCE_IMAGE_QUALITY = 0.85;

const buildPromptWithImages = (text: string, imageCount: number) => {
    if (imageCount <= 0) return text;
    let prompt = text;
    prompt += `\n\n[${imageCount} image attachment${imageCount === 1 ? "" : "s"} provided]`;
    for (let index = 0; index < imageCount; index += 1) {
        prompt += `\n${MEDIA_MARKER}`;
    }
    return prompt;
};

const CHAT_SYSTEM_PROMPT =
    "You are a helpful assistant. Use Markdown **bold** to emphasize important terms and key points. For math equations, put $$ on its own line (never inline). Example:\n$$\nx^2 + y^2 = z^2\n$$";

const SESSION_TITLE_PROMPT =
    "You create concise chat titles. Given the provided message, summarize the user's goal in 5-7 words. Use plain words, no quotes, no emojis, no trailing punctuation, and output only the title.";

type DocumentAttachment = {
    id: string;
    name: string;
    text: string;
    size: number;
};

type ImageAttachment = {
    id: string;
    name: string;
    size: number;
    file: File;
};

const createDocumentBlockRegex = () =>
    /----- BEGIN DOCUMENT: ([^\n]+) -----\n([\s\S]*?)\n----- END DOCUMENT: \1 -----/g;

const createDocumentId = () => {
    if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
        return crypto.randomUUID();
    }
    return `doc_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
};

const createAttachmentId = () => createDocumentId();

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
            // Remove null bytes which are invalid in C strings used by llama.cpp
            const content = doc.text.replace(/\0/g, '').trim();
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

const sanitizeImageExtension = (filename?: string) => {
    if (!filename) return undefined;
    const extension = filename.split(".").pop();
    if (!extension) return undefined;
    const cleaned = extension.replace(/[^a-z0-9]+/gi, "");
    return cleaned || undefined;
};

const prepareInferenceImageBytes = async (image: ImageAttachment) => {
    const fallback = async () => ({
        bytes: new Uint8Array(await image.file.arrayBuffer()),
        extension: sanitizeImageExtension(image.name),
    });

    if (typeof document === "undefined") {
        return fallback();
    }

    const resizeToJpeg = async (
        width: number,
        height: number,
        draw: (ctx: CanvasRenderingContext2D, w: number, h: number) => void,
    ) => {
        const maxDimension = MAX_INFERENCE_IMAGE_DIMENSION;
        if (width <= maxDimension && height <= maxDimension) {
            return null;
        }
        const scale = maxDimension / Math.max(width, height);
        const targetWidth = Math.max(1, Math.round(width * scale));
        const targetHeight = Math.max(1, Math.round(height * scale));
        const canvas = document.createElement("canvas");
        canvas.width = targetWidth;
        canvas.height = targetHeight;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
            return null;
        }
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";
        draw(ctx, targetWidth, targetHeight);
        const blob = await new Promise<Blob>((resolve, reject) => {
            canvas.toBlob(
                (result) => {
                    if (result) {
                        resolve(result);
                    } else {
                        reject(new Error("Failed to encode image"));
                    }
                },
                "image/jpeg",
                INFERENCE_IMAGE_QUALITY,
            );
        });
        const bytes = new Uint8Array(await blob.arrayBuffer());
        return { bytes, extension: "jpg" };
    };

    let bitmap: ImageBitmap | null = null;
    try {
        if (typeof createImageBitmap !== "undefined") {
            bitmap = await createImageBitmap(image.file);
            const resized = await resizeToJpeg(
                bitmap.width,
                bitmap.height,
                (ctx, w, h) => {
                    ctx.drawImage(bitmap as ImageBitmap, 0, 0, w, h);
                },
            );
            if (resized) {
                return resized;
            }
        }
    } catch (error) {
        log.error("Failed to resize image with ImageBitmap", error);
    } finally {
        bitmap?.close();
    }

    try {
        const resized = await new Promise<{
            bytes: Uint8Array;
            extension: string;
        } | null>((resolve, reject) => {
            const url = URL.createObjectURL(image.file);
            const img = new Image();
            const cleanup = () => URL.revokeObjectURL(url);
            img.onload = () => {
                resizeToJpeg(img.width, img.height, (ctx, w, h) => {
                    ctx.drawImage(img, 0, 0, w, h);
                })
                    .then((result) => {
                        cleanup();
                        resolve(result);
                    })
                    .catch((err) => {
                        cleanup();
                        reject(err);
                    });
            };
            img.onerror = () => {
                cleanup();
                reject(new Error("Failed to decode image"));
            };
            img.src = url;
        });
        if (resized) {
            return resized;
        }
    } catch (error) {
        log.error("Failed to resize image with Image element", error);
    }

    return fallback();
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
    const assetBasePath = router.basePath ?? "";
    const logoSrc = `${assetBasePath}/images/ensu-logo.svg`;
    const [isDarkMode, setIsDarkMode] = useState(
        theme.palette.mode === "dark",
    );

    useEffect(() => {
        if (typeof window === "undefined") return;
        const updateMode = () => {
            const value = getComputedStyle(document.documentElement)
                .getPropertyValue("--mui-palette-background-default")
                .trim();
            const resolved =
                value && !value.startsWith("var(")
                    ? value
                    : theme.palette.background.default;
            try {
                setIsDarkMode(getLuminance(resolved) < 0.5);
            } catch {
                setIsDarkMode(theme.palette.mode === "dark");
            }
        };

        updateMode();
        const observer = new MutationObserver(updateMode);
        observer.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ["class", "style"],
        });
        return () => observer.disconnect();
    }, [theme.palette.background.default, theme.palette.mode]);

    const logoFilter = isDarkMode ? "none" : "invert(1)";
    const userBubbleBackground = isDarkMode
        ? "fill.faintHover"
        : "fill.faint";
    const messageTypographySx = {
        fontSize: "15px",
        lineHeight: "26px",
        fontWeight: 400,
    } as const;
    const userMessageTextSx = {
        ...messageTypographySx,
        color: "text.base",
        textAlign: "right",
        whiteSpace: "pre-wrap",
        fontFamily: '"Inter", sans-serif',
    } as const;
    const assistantTextSx = {
        ...messageTypographySx,
        color: "text.base",
        textAlign: "left",
        whiteSpace: "pre-wrap",
        fontFamily: '"Inter", sans-serif',
    } as const;
    const assistantMarkdownSx = {
        ...messageTypographySx,
        color: "text.base",
        fontFamily: '"Inter", sans-serif',
        "& p": { margin: 0 },
        "& p + p": { marginTop: "12px" },
        "& ul, & ol": { paddingLeft: "24px", margin: "12px 0 0" },
        "& li": { marginBottom: "4px" },
        "& code": {
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: "0.95em",
        },
        "& pre": {
            margin: "12px 0 0",
            padding: "12px",
            borderRadius: 12,
            backgroundColor: isDarkMode
                ? "rgba(255, 255, 255, 0.06)"
                : "rgba(0, 0, 0, 0.04)",
            overflowX: "auto",
        },
        "& pre code": {
            fontFamily: '"JetBrains Mono", monospace',
        },
        "& blockquote": {
            margin: "12px 0 0",
            paddingLeft: "12px",
            borderLeft: "3px solid",
            borderLeftColor: "divider",
            color: "text.muted",
        },
        "& .katex-display": {
            margin: "12px 0 0",
            padding: "12px",
            borderRadius: 12,
            backgroundColor:
                theme.palette.mode === "dark"
                    ? "rgba(255, 255, 255, 0.06)"
                    : "rgba(0, 0, 0, 0.04)",
            overflowX: "auto",
        },
        "& .katex": {
            color: "text.base",
        },
        "& a": { color: "accent.main" },
    };
    const streamingMessageSx = {
        transition: "all 0.2s ease",
    } as const;
    const cursorSx = {
        display: "inline-block",
        width: "0.6ch",
        marginLeft: "2px",
        animation: "ensu-blink 1s steps(1, end) infinite",
        "@keyframes ensu-blink": {
            "0%, 50%": { opacity: 1 },
            "50.01%, 100%": { opacity: 0 },
        },
    } as const;
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
    const tinyIconProps = { size: 16, strokeWidth: 2 } as const;
    const dialogTitleSx = {
        fontFamily: '"DM Serif Text", serif',
        fontWeight: 400,
    } as const;
    const settingsItemSx = {
        alignItems: "center",
        gap: 1,
        px: 2,
        py: 1.25,
        borderRadius: 2,
        border: "1px solid",
        borderColor: "divider",
        bgcolor: "fill.faint",
        "&:hover": { bgcolor: "fill.faintHover" },
    } as const;

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
    const [chatViewportWidth, setChatViewportWidth] = useState(() =>
        typeof window !== "undefined" ? window.innerWidth : 0,
    );
    const [sessionSearch, setSessionSearch] = useState("");
    const [showSessionSearch, setShowSessionSearch] = useState(false);
    const [showSettingsModal, setShowSettingsModal] = useState(false);
    const [showDeveloperMenu, setShowDeveloperMenu] = useState(false);
    const [showComingSoon, setShowComingSoon] = useState(false);
    const [isDraftSession, setIsDraftSession] = useState(false);
    const [stickToBottom, setStickToBottom] = useState(true);
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
    const [pendingImages, setPendingImages] = useState<ImageAttachment[]>([]);
    const [attachmentAnchor, setAttachmentAnchor] =
        useState<HTMLElement | null>(null);
    const [syncNotification, setSyncNotification] = useState<
        NotificationAttributes | undefined
    >(undefined);
    const [syncNotificationOpen, setSyncNotificationOpen] = useState(false);
    const [isGenerating, setIsGenerating] = useState(false);
    const [loadingPhrase, setLoadingPhrase] = useState<string | null>(null);
    const [loadingDots, setLoadingDots] = useState(1);
    const [isDownloading, setIsDownloading] = useState(false);
    const [attachmentPreviews, setAttachmentPreviews] = useState<
        Record<string, string>
    >({});
    const [pendingImagePreviews, setPendingImagePreviews] = useState<
        Record<string, string>
    >({});
    const [downloadStatus, setDownloadStatus] = useState<
        DownloadProgress | null
    >(null);
    const [loadedModelName, setLoadedModelName] = useState<string | null>(null);
    const [modelGateStatus, setModelGateStatus] = useState<
        | "checking"
        | "missing"
        | "preloading"
        | "downloading"
        | "ready"
        | "error"
    >("checking");
    const [modelGateError, setModelGateError] = useState<string | null>(null);
    const [isTauriRuntime, setIsTauriRuntime] = useState(false);
    const [deleteSessionId, setDeleteSessionId] = useState<string | null>(null);

    const allowMmproj = isTauriRuntime;

    const providerRef = useRef<LlmProvider | null>(null);
    const currentJobIdRef = useRef<number | null>(null);
    const pendingCancelRef = useRef(false);
    const stopRequestedRef = useRef(false);
    const generationTokenRef = useRef(0);
    const lastGenerationRef = useRef<
        | { parentMessageUuid: string; previousSelection?: string | null }
        | null
    >(null);
    const sessionSummaryInFlightRef = useRef(false);
    const inputRef = useRef<HTMLTextAreaElement | null>(null);
    const attachmentPreviewUrlsRef = useRef<Record<string, string>>({});
    const pendingPreviewUrlsRef = useRef<Record<string, string>>({});
    const chatViewportRef = useRef<HTMLDivElement | null>(null);
    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const lastScrollTopRef = useRef(0);
    const userScrollIntentRef = useRef(false);
    const userScrollTimeoutRef = useRef<number | null>(null);
    const currentSessionIdRef = useRef<string | undefined>(undefined);
    const isDraftSessionRef = useRef(false);
    const logoClickCountRef = useRef(0);
    const logoClickTimeoutRef = useRef<number | null>(null);
    const streamingBufferRef = useRef("");
    const streamingFlushTimerRef = useRef<number | null>(null);
    const lastDownloadProgressRef = useRef(0);
    const pendingDownloadProgressRef = useRef<DownloadProgress | null>(null);
    const downloadProgressTimerRef = useRef<number | null>(null);

    const authRefreshCancelledRef = useRef(false);
    const authRetryCancelledRef = useRef(false);

    const sessionFromQuery = useMemo(() => {
        if (!router.isReady) return undefined;
        const value = router.query.session;
        if (Array.isArray(value)) return value[0];
        return typeof value === "string" ? value : undefined;
    }, [router.isReady, router.query.session]);

    const lastRouteUpdateRef = useRef<{
        sessionId?: string;
        at: number;
    }>({ sessionId: undefined, at: 0 });
    const routeInitializedRef = useRef(false);

    const updateRouteSession = useCallback(
        (sessionId: string | undefined, replace = false) => {
            if (!router.isReady) return;

            const current = Array.isArray(router.query.session)
                ? router.query.session[0]
                : typeof router.query.session === "string"
                  ? router.query.session
                  : undefined;

            if (current === sessionId) return;

            const now = Date.now();
            const last = lastRouteUpdateRef.current;
            if (last.sessionId === sessionId && now - last.at < 1000) {
                return;
            }
            lastRouteUpdateRef.current = { sessionId, at: now };

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
        const hasToken = !!token;
        setIsLoggedIn(hasToken);

        log.info("Refreshing auth state", { hasToken });

        if (hasToken) {
            const cachedRemote = cachedChatKey();
            if (cachedRemote) {
                log.info("Using cached remote chat key");
                setChatKey(cachedRemote);
            }

            try {
                const masterKey = await masterKeyFromSession();
                if (masterKey) {
                    log.info("Found master key in session, deriving chat key");
                    const remoteKey = await getOrCreateChatKey(masterKey);
                    setChatKey(remoteKey);
                    return;
                } else {
                    log.warn("No master key found in session storage");
                }
            } catch (error) {
                log.error("Failed to derive chat key", error);
            }

            if (cachedRemote) {
                return;
            }
        }

        const cachedLocal = cachedLocalChatKey();
        if (cachedLocal) {
            log.info("Falling back to cached local chat key");
            setChatKey(cachedLocal);
            return;
        }

        try {
            log.info("Generating new local chat key");
            setChatKey(await getOrCreateLocalChatKey());
        } catch (error) {
            log.error("Failed to initialize local chat key", error);
            showMiniDialog({
                title: "Encryption error",
                message:
                    "We could not initialize encryption. Please refresh the page.",
            });
        }
    }, [showMiniDialog]);

    useEffect(() => {
        authRefreshCancelledRef.current = false;

        void (async () => {
            try {
                await refreshAuthState();
            } catch (error) {
                log.error("Failed to refresh auth state", error);
            }
            if (!authRefreshCancelledRef.current) setLoading(false);
        })();

        return () => {
            authRefreshCancelledRef.current = true;
        };
    }, [refreshAuthState]);

    useEffect(() => {
        routeInitializedRef.current = false;
    }, [chatKey]);

    useEffect(() => {
        isDraftSessionRef.current = isDraftSession;
    }, [isDraftSession]);

    useEffect(() => {
        if (typeof window === "undefined") return;

        authRetryCancelledRef.current = false;
        let attempts = 0;
        let timeoutId: number | undefined;

        const retry = async () => {
            if (authRetryCancelledRef.current) return;
            const token = await savedAuthToken();
            const masterKey = await masterKeyFromSession();
            const remoteKey = cachedChatKey();

            // If we are logged in, we want to wait for either the master key to
            // appear in session storage, or for a previously cached remote key
            // to be available.
            if (token && (masterKey || remoteKey)) {
                await refreshAuthState();
                return;
            }

            // If we're not logged in, we just retry a few times to see if a
            // login token appears (e.g. from a recent redirect).
            if (!token && attempts >= 5) {
                return;
            }

            attempts += 1;
            if (attempts < 15) {
                timeoutId = window.setTimeout(retry, 600);
            }
        };

        timeoutId = window.setTimeout(retry, 600);

        return () => {
            authRetryCancelledRef.current = true;
            if (timeoutId) window.clearTimeout(timeoutId);
        };
    }, [refreshAuthState]);

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
        if (loading || typeof window === "undefined") return;
        const element = chatViewportRef.current;
        if (!element) return;

        const updateWidth = () => {
            setChatViewportWidth(element.getBoundingClientRect().width);
        };

        updateWidth();

        if (typeof ResizeObserver === "undefined") {
            const handleResize = () => updateWidth();
            window.addEventListener("resize", handleResize);
            return () => window.removeEventListener("resize", handleResize);
        }

        const observer = new ResizeObserver(() => updateWidth());
        observer.observe(element);
        return () => observer.disconnect();
    }, [loading]);

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
            setMmprojUrl(allowMmproj ? parsed.mmprojUrl ?? "" : "");
            setContextLength(parsed.contextLength ?? "");
            setMaxTokens(parsed.maxTokens ?? "");
        } catch (error) {
            log.error("Failed to read model settings", error);
        }
    }, [allowMmproj]);

    const applyDownloadProgress = useCallback((progress: DownloadProgress) => {
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

    const handleDownloadProgress = useCallback(
        (progress: DownloadProgress) => {
            const status = progress.status?.toLowerCase() ?? "";
            const isTerminal =
                progress.percent < 0 ||
                progress.percent >= 100 ||
                status.includes("ready");

            if (isTerminal) {
                if (downloadProgressTimerRef.current) {
                    window.clearTimeout(downloadProgressTimerRef.current);
                    downloadProgressTimerRef.current = null;
                }
                pendingDownloadProgressRef.current = null;
                lastDownloadProgressRef.current = Date.now();
                applyDownloadProgress(progress);
                return;
            }

            const now = Date.now();
            const elapsed = now - lastDownloadProgressRef.current;
            if (elapsed >= 120) {
                lastDownloadProgressRef.current = now;
                applyDownloadProgress(progress);
                return;
            }

            pendingDownloadProgressRef.current = progress;
            if (!downloadProgressTimerRef.current) {
                downloadProgressTimerRef.current = window.setTimeout(() => {
                    const pending = pendingDownloadProgressRef.current;
                    if (pending) {
                        applyDownloadProgress(pending);
                        lastDownloadProgressRef.current = Date.now();
                        pendingDownloadProgressRef.current = null;
                    }
                    downloadProgressTimerRef.current = null;
                }, Math.max(20, 120 - elapsed));
            }
        },
        [applyDownloadProgress],
    );

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
        try {
            const loaded = await listSessions(chatKey);
            if (loaded.length === 0) {
                setSessions([]);
                setCurrentSessionId(undefined);
                setAllMessages([]);
                if (!routeInitializedRef.current) {
                    updateRouteSession(undefined, true);
                    routeInitializedRef.current = true;
                }
                return;
            }

            setSessions(loaded);

            if (isDraftSessionRef.current && !currentSessionIdRef.current) {
                if (!routeInitializedRef.current) {
                    updateRouteSession(undefined, true);
                    routeInitializedRef.current = true;
                }
                return;
            }

            const hasQuerySession =
                sessionFromQuery &&
                loaded.some(
                    (session) => session.sessionUuid === sessionFromQuery,
                );

            const nextSessionId = hasQuerySession
                ? sessionFromQuery
                : (currentSessionId ?? loaded[0]?.sessionUuid);

            if (nextSessionId) {
                setCurrentSessionId(nextSessionId);
                currentSessionIdRef.current = nextSessionId;
                setIsDraftSession(false);
                isDraftSessionRef.current = false;
                if (nextSessionId !== sessionFromQuery) {
                    if (!routeInitializedRef.current) {
                        updateRouteSession(nextSessionId, true);
                        routeInitializedRef.current = true;
                    }
                } else {
                    routeInitializedRef.current = true;
                }
            }
        } catch (error) {
            log.error("Failed to refresh sessions", error);
            showMiniDialog({
                title: "Chat unavailable",
                message:
                    "We could not load your chat data. Please refresh the page.",
            });
        }
    }, [
        chatKey,
        currentSessionId,
        isDraftSession,
        sessionFromQuery,
        updateRouteSession,
        showMiniDialog,
    ]);

    const refreshMessages = useCallback(
        async (sessionId: string | undefined = currentSessionId) => {
            if (!chatKey || !sessionId) {
                setAllMessages([]);
                return;
            }
            const activeSessionId = sessionId;
            const loaded = await listMessages(activeSessionId, chatKey);
            if (currentSessionIdRef.current !== activeSessionId) return;
            setAllMessages(loaded);
        },
        [chatKey, currentSessionId],
    );

    const syncNow = useCallback(
        async ({ showToast = false }: { showToast?: boolean } = {}) => {
            if (!chatKey) return;
            const remoteKey = cachedChatKey();
            const canSync =
                isLoggedIn && !!remoteKey && remoteKey === chatKey;

            if (canSync) {
                try {
                    await syncChat(chatKey);
                    if (showToast) {
                        setSyncNotification({
                            title: "Sync complete",
                            caption: "Your chats are up to date.",
                            color: "accent",
                            autoHideDuration: 3000,
                        });
                        setSyncNotificationOpen(true);
                    }
                } catch (error) {
                    log.error("Chat sync failed", error);
                    if (showToast) {
                        setSyncNotification({
                            title: "Sync failed",
                            caption:
                                error instanceof ChatSyncLimitError
                                    ? error.message
                                    : "We could not sync right now.",
                            color: "critical",
                            autoHideDuration: 4000,
                        });
                        setSyncNotificationOpen(true);
                    }
                    if (error instanceof ChatSyncLimitError) {
                        showMiniDialog({
                            title: "Sync limit reached",
                            message: error.message,
                        });
                    }
                }
            } else if (showToast) {
                setSyncNotification({
                    title: "Sync unavailable",
                    caption: "Encryption is still initializing.",
                    color: "critical",
                    autoHideDuration: 3000,
                });
                setSyncNotificationOpen(true);
            }

            await refreshSessions();
            await refreshMessages();
        },
        [
            chatKey,
            isLoggedIn,
            refreshMessages,
            refreshSessions,
            showMiniDialog,
            setSyncNotification,
            setSyncNotificationOpen,
        ],
    );

    useEffect(() => {
        if (typeof window === "undefined") return;
        if (!chatKey || !isLoggedIn) return;
        const intervalId = window.setInterval(() => {
            void syncNow();
        }, 60_000);
        return () => {
            window.clearInterval(intervalId);
        };
    }, [chatKey, isLoggedIn, syncNow]);

    useEffect(() => {
        if (typeof window === "undefined") return;

        const handleFocus = () => {
            void refreshAuthState();
            if (chatKey && isLoggedIn) {
                void syncNow();
            }
        };

        const handleVisibility = () => {
            if (!document.hidden) {
                void refreshAuthState();
                if (chatKey && isLoggedIn) {
                    void syncNow();
                }
            }
        };

        window.addEventListener("focus", handleFocus);
        document.addEventListener("visibilitychange", handleVisibility);

        return () => {
            window.removeEventListener("focus", handleFocus);
            document.removeEventListener("visibilitychange", handleVisibility);
        };
    }, [chatKey, isLoggedIn, refreshAuthState, syncNow]);

    const deleteSessionTarget = useMemo(
        () =>
            deleteSessionId
                ? sessions.find(
                      (session) => session.sessionUuid === deleteSessionId,
                  )
                : undefined,
        [deleteSessionId, sessions],
    );

    const deleteSessionLabel = useMemo(() => {
        const title = deleteSessionTarget?.title?.trim();
        if (title && title !== "New chat") {
            return `"${title}"`;
        }
        return "this chat";
    }, [deleteSessionTarget]);

    useEffect(() => {
        if (!chatKey) return;
        if (isLoggedIn) {
            void syncNow();
            return;
        }
        void refreshSessions();
    }, [chatKey, isLoggedIn, refreshSessions, syncNow]);

    useEffect(() => {
        currentSessionIdRef.current = currentSessionId;
        void refreshMessages();
    }, [currentSessionId, refreshMessages]);


    useEffect(() => {
        if (isDraftSession) return;
        if (!sessionFromQuery || sessions.length === 0) return;
        if (
            sessionFromQuery !== currentSessionId &&
            sessions.some((session) => session.sessionUuid === sessionFromQuery)
        ) {
            setCurrentSessionId(sessionFromQuery);
        }
    }, [currentSessionId, isDraftSession, sessionFromQuery, sessions]);

    useEffect(() => {
        setStreamingParentId(null);
        setStreamingText("");
        setIsGenerating(false);
        setPendingDocuments([]);
        setPendingImages([]);
        setStickToBottom(true);
        currentJobIdRef.current = null;
        pendingCancelRef.current = false;
    }, [currentSessionId]);

    useEffect(() => {
        if (!isGenerating || streamingText.trim().length > 0) {
            setLoadingPhrase(null);
            setLoadingDots(1);
            return;
        }

        setLoadingPhrase((prev) => prev ?? randomLoadingPhrase());
        const timer = window.setInterval(() => {
            setLoadingDots((prev) => (prev % 3) + 1);
        }, 450);

        return () => {
            window.clearInterval(timer);
        };
    }, [isGenerating, streamingText]);

    const inferImageMime = useCallback((name: string) => {
        const extension = name.split(".").pop()?.toLowerCase();
        switch (extension) {
            case "png":
                return "image/png";
            case "webp":
                return "image/webp";
            case "gif":
                return "image/gif";
            case "jpeg":
            case "jpg":
                return "image/jpeg";
            default:
                return "image/*";
        }
    }, []);

    useEffect(() => {
        const next = { ...pendingPreviewUrlsRef.current };
        const activeIds = new Set(pendingImages.map((image) => image.id));

        Object.keys(next).forEach((id) => {
            if (!activeIds.has(id)) {
                const url = next[id];
                if (url) {
                    URL.revokeObjectURL(url);
                }
                delete next[id];
            }
        });

        pendingImages.forEach((image) => {
            if (!next[image.id]) {
                next[image.id] = URL.createObjectURL(image.file);
            }
        });

        pendingPreviewUrlsRef.current = next;
        setPendingImagePreviews(next);
    }, [pendingImages]);


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

    useEffect(() => {
        const container = scrollContainerRef.current;
        if (!container || !stickToBottom) return;
        container.scrollTo({ top: container.scrollHeight, behavior: "auto" });
    }, [displayMessages.length, streamingText, isGenerating, stickToBottom]);

    useEffect(() => {
        if (!chatKey) return;
        let cancelled = false;
        const activeIds = new Set<string>();

        displayMessages.forEach((message) => {
            (message.attachments ?? []).forEach((attachment) => {
                if (attachment.kind === "image") {
                    activeIds.add(attachment.id);
                }
            });
        });

        setAttachmentPreviews((prev) => {
            const next = { ...prev };
            Object.keys(next).forEach((id) => {
                if (!activeIds.has(id)) {
                    const url = next[id];
                    if (url) {
                        URL.revokeObjectURL(url);
                    }
                    delete next[id];
                }
            });
            attachmentPreviewUrlsRef.current = next;
            return next;
        });

        const toLoad: Array<{ id: string; sessionUuid: string; name: string }> = [];
        displayMessages.forEach((message) => {
            (message.attachments ?? []).forEach((attachment) => {
                if (
                    attachment.kind === "image" &&
                    !attachmentPreviewUrlsRef.current[attachment.id]
                ) {
                    toLoad.push({
                        id: attachment.id,
                        sessionUuid: message.sessionUuid,
                        name: attachment.name,
                    });
                }
            });
        });

        if (toLoad.length === 0) return;

        void (async () => {
            const results = await Promise.all(
                toLoad.map(async (item) => {
                    try {
                        await downloadAttachment(item.id);
                        const bytes = await readDecryptedAttachmentBytes(
                            item.id,
                            chatKey,
                            item.sessionUuid,
                        );
                        const blob = new Blob([bytes], {
                            type: inferImageMime(item.name),
                        });
                        const url = URL.createObjectURL(blob);
                        return { id: item.id, url };
                    } catch (error) {
                        log.error("Failed to load image preview", error);
                        return null;
                    }
                }),
            );

            if (cancelled) {
                results.forEach((result) => {
                    if (result?.url) {
                        URL.revokeObjectURL(result.url);
                    }
                });
                return;
            }

            setAttachmentPreviews((prev) => {
                const next = { ...prev };
                results.forEach((result) => {
                    if (result?.url) {
                        next[result.id] = result.url;
                    }
                });
                attachmentPreviewUrlsRef.current = next;
                return next;
            });
        })();

        return () => {
            cancelled = true;
        };
    }, [
        chatKey,
        displayMessages,
        downloadAttachment,
        inferImageMime,
        readDecryptedAttachmentBytes,
    ]);

    const showDrawerToggle = isSmall || drawerCollapsed;
    const drawerWidth = isSmall ? 300 : drawerCollapsed ? 0 : 320;
    const desktopBreakpoint = theme.breakpoints.values.lg ?? 1200;
    const isDesktopOverlay =
        !isSmall && chatViewportWidth >= desktopBreakpoint;
    const showAttachmentPicker = isTauriRuntime;
    const showImageAttachment =
        showAttachmentPicker && DESKTOP_IMAGE_ATTACHMENTS_ENABLED;
    const showDownloadProgress =
        !!downloadStatus?.status && downloadStatus.status !== "Ready";
    const showModelGate =
        modelGateStatus === "missing" ||
        modelGateStatus === "error" ||
        modelGateStatus === "downloading";

    const downloadSizeLabel = useMemo(() => {
        if (useCustomModel) {
            return "Approx. size varies by model";
        }
        return DEFAULT_MODEL.sizeHuman
            ? `Approx. ${DEFAULT_MODEL.sizeHuman}`
            : "Approx. size varies by model";
    }, [useCustomModel]);

    const downloadStatusLabel = useMemo(() => {
        if (!showDownloadProgress) return null;
        const status = downloadStatus?.status ?? "";
        if (status.toLowerCase().includes("loading")) {
            return status;
        }
        if (downloadStatus?.totalBytes && downloadStatus.percent >= 0) {
            const downloaded = downloadStatus.bytesDownloaded ?? 0;
            return `Downloading... ${formatBytes(downloaded)} / ${formatBytes(downloadStatus.totalBytes)}`;
        }
        if (status) return status;
        return "Downloading...";
    }, [downloadStatus, showDownloadProgress]);

    const focusInput = useCallback(() => {
        if (showModelGate) return;
        if (typeof window === "undefined") return;
        const target = inputRef.current;
        if (!target) return;
        window.requestAnimationFrame(() => {
            target.focus();
        });
    }, [showModelGate]);

    useEffect(() => {
        if (showSessionSearch) return;
        focusInput();
    }, [currentSessionId, isDraftSession, showModelGate, showSessionSearch, focusInput]);

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
                allowMmproj && mmprojUrl.trim()
                    ? mmprojUrl.trim()
                    : undefined,
            contextLength: contextLength ? Number(contextLength) : undefined,
            maxTokens: maxTokens ? Number(maxTokens) : undefined,
        };
    }, [useCustomModel, modelUrl, mmprojUrl, contextLength, maxTokens, allowMmproj]);

    const modelSettingsKey = useMemo(
        () => JSON.stringify(getModelSettings()),
        [getModelSettings],
    );

    const formatErrorMessage = useCallback((error: unknown) => {
        if (error instanceof Error) return error.message;
        if (typeof error === "string") return error;
        if (error && typeof error === "object") {
            const maybeMessage = (error as { message?: unknown }).message;
            if (typeof maybeMessage === "string" && maybeMessage.trim()) {
                return maybeMessage;
            }
            if ("__wbg_ptr" in error) {
                return "Model failed to start. Please refresh and try again.";
            }
            const text = String(error);
            if (text && text !== "[object Object]") {
                return text;
            }
        }
        try {
            return JSON.stringify(error);
        } catch {
            return String(error);
        }
    }, []);

    const trimToWords = useCallback((text: string, maxWords: number) => {
        const normalized = text.replace(/\u0000/g, "").replace(/\s+/g, " ").trim();
        if (!normalized) return "";
        const words = normalized.split(" ").filter(Boolean);
        return words.slice(0, maxWords).join(" ");
    }, []);

    const writeInferenceImages = useCallback(
        async (images: ImageAttachment[]) => {
            if (!isTauriRuntime || images.length === 0) return [] as string[];
            const { appDataDir, join } = await import("@tauri-apps/api/path");
            const { createDir, writeBinaryFile } = await import(
                "@tauri-apps/api/fs"
            );
            const root = await appDataDir();
            const dir = await join(root, "ensu_llmchat_inference_images");
            await createDir(dir, { recursive: true });

            const paths = await Promise.all(
                images.map(async (image) => {
                    const { bytes, extension } =
                        await prepareInferenceImageBytes(image);
                    const suffix = extension ? `.${extension}` : ".jpg";
                    const path = await join(dir, `${image.id}${suffix}`);
                    await writeBinaryFile({ path, contents: bytes });
                    return path;
                }),
            );

            return paths;
        },
        [isTauriRuntime],
    );

    const cleanupInferenceImages = useCallback(async (paths: string[]) => {
        if (!isTauriRuntime || paths.length === 0) return;
        const { removeFile } = await import("@tauri-apps/api/fs");
        await Promise.all(
            paths.map(async (path) => {
                try {
                    await removeFile(path);
                } catch {
                    // ignore cleanup failures
                }
            }),
        );
    }, [isTauriRuntime]);

    const generateSessionSummary = useCallback(
        async (input: string) => {
            const provider = await ensureProvider();
            const settings = getModelSettings();
            const availability = await provider.checkModelAvailability(settings);
            const mmprojReady =
                availability.mmprojAvailable === undefined ||
                availability.mmprojAvailable;

            if (!availability.modelAvailable || !mmprojReady) {
                return null;
            }

            await provider.ensureModelReady(settings);

            let summary = "";
            let errorMessage: string | null = null;

            await provider.generateChatStream(
                {
                    messages: [
                        { role: "system", content: SESSION_TITLE_PROMPT },
                        { role: "user", content: input },
                    ],
                    maxTokens: 64,
                    temperature: 0.2,
                    topP: 0.9,
                },
                (event) => {
                    if (event.type === "text") {
                        summary += event.text;
                        return;
                    }
                    if (event.type === "error") {
                        errorMessage = event.message;
                    }
                },
            );

            if (errorMessage) {
                throw new Error(errorMessage);
            }

            return summary;
        },
        [ensureProvider, getModelSettings],
    );

    const maybeGenerateSessionTitle = useCallback(
        async ({
            sessionUuid,
            assistantMessageUuid,
            wasInterrupted,
        }: {
            sessionUuid: string;
            assistantMessageUuid: string;
            wasInterrupted: boolean;
        }) => {
            if (!chatKey || wasInterrupted) return;
            if (sessionSummaryInFlightRef.current) return;
            sessionSummaryInFlightRef.current = true;

            try {
                const messages = await listMessages(sessionUuid, chatKey);
                const assistantMessages = messages.filter(
                    (message) => message.sender === "assistant",
                );
                if (assistantMessages.length !== 1) return;

                const firstAssistant = assistantMessages[0];
                if (!firstAssistant) return;
                if (firstAssistant.messageUuid !== assistantMessageUuid) return;

                const firstUser = messages.find(
                    (message) => message.sender === "self",
                );
                if (!firstUser) return;

                const userText = parseDocumentBlocks(firstUser.text).text;
                const assistantText = stripHiddenParts(firstAssistant.text);

                const fallbackSeed =
                    trimToWords(userText, 7) || "New chat";
                const fallbackTitle = sessionTitleFromText(
                    fallbackSeed,
                    "New chat",
                );

                const summaryInput = `User: ${userText}\nAssistant: ${assistantText}`;
                const summary = await generateSessionSummary(summaryInput);
                const summarySeed = summary
                    ? trimToWords(summary, 7)
                    : "";
                const title = summarySeed
                    ? sessionTitleFromText(summarySeed, fallbackTitle)
                    : fallbackTitle;

                await updateSessionTitle(sessionUuid, title, chatKey);
                await refreshSessions();
            } catch (error) {
                log.error("Failed to generate session title", error);
            } finally {
                sessionSummaryInFlightRef.current = false;
            }
        },
        [
            chatKey,
            generateSessionSummary,
            refreshSessions,
            trimToWords,
        ],
    );

    const preloadModelIfAvailable = useCallback(async () => {
        setModelGateError(null);
        setModelGateStatus("checking");

        try {
            const provider = await ensureProvider();
            const settings = getModelSettings();
            const availability = await provider.checkModelAvailability(settings);
            const mmprojReady =
                availability.mmprojAvailable === undefined ||
                availability.mmprojAvailable;

            if (!availability.modelAvailable || !mmprojReady) {
                setModelGateStatus("missing");
                return;
            }

            setModelGateStatus("preloading");
            setDownloadStatus({ percent: 0, status: "Loading model..." });
            setIsDownloading(true);

            await provider.ensureModelReady(settings);
            setLoadedModelName(provider.getCurrentModel()?.name ?? null);
            setIsDownloading(false);
            setDownloadStatus({ percent: 100, status: "Ready" });
            setModelGateStatus("ready");
        } catch (error) {
            const message = formatErrorMessage(error);
            log.error("Failed to preload model", error);
            setModelGateError(message);
            setIsDownloading(false);
            setModelGateStatus("error");
        }
    }, [ensureProvider, formatErrorMessage, getModelSettings]);

    const handleDownloadModel = useCallback(async () => {
        setModelGateError(null);
        setModelGateStatus("downloading");
        setDownloadStatus({ percent: 0, status: "Preparing download..." });
        setIsDownloading(true);

        try {
            const provider = await ensureProvider();
            const settings = getModelSettings();
            await provider.ensureModelReady(settings);
            setLoadedModelName(provider.getCurrentModel()?.name ?? null);
            setIsDownloading(false);
            setDownloadStatus({ percent: 100, status: "Ready" });
            setModelGateStatus("ready");
        } catch (error) {
            const message = formatErrorMessage(error);
            log.error("Failed to prepare model", error);
            setModelGateError(message);
            setIsDownloading(false);
            setModelGateStatus("error");
            showMiniDialog({
                title: "Model error",
                message,
            });
        }
    }, [ensureProvider, formatErrorMessage, getModelSettings, showMiniDialog]);

    useEffect(() => {
        void preloadModelIfAvailable();
    }, [modelSettingsKey, preloadModelIfAvailable]);

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
            .replace(/\u0000/g, "")
            .replace(/<think>[\s\S]*?<\/think>/g, "")
            .replace(/<todo_list>[\s\S]*?<\/todo_list>/g, "")
            .trim();
    }, []);

    const approxTokens = useCallback((text: string) => {
        if (!text) return 0;
        const baseTokens = Math.ceil(text.length / 4);
        const imageCount = text.split(MEDIA_MARKER).length - 1;
        return baseTokens + imageCount * IMAGE_TOKEN_ESTIMATE;
    }, []);

    const loadMessageDocuments = useCallback(
        async (message: ChatMessage): Promise<DocumentAttachment[]> => {
            if (!chatKey) return [];
            const attachments = (message.attachments ?? []).filter(
                (attachment) => attachment.kind === "document",
            );
            if (attachments.length === 0) return [];

            try {
                const docs = await Promise.all(
                    attachments.map(async (attachment) => {
                        await downloadAttachment(attachment.id);
                        const bytes = await readDecryptedAttachmentBytes(
                            attachment.id,
                            chatKey,
                            message.sessionUuid,
                        );
                        const text = new TextDecoder().decode(bytes);
                        return {
                            id: attachment.id,
                            name: attachment.name,
                            text: text.replace(/\u0000/g, ""),
                            size: bytes.length,
                        } satisfies DocumentAttachment;
                    }),
                );
                return docs;
            } catch (error) {
                log.error("Failed to load attachment contents", error);
                return [];
            }
        },
        [chatKey, downloadAttachment, readDecryptedAttachmentBytes],
    );

    const buildHistory = useCallback(
        async (
            path: ChatMessage[],
            promptText: string,
            contextSize: number,
            maxTokensCount: number,
            stopAtMessageUuid?: string | null,
        ): Promise<LlmMessage[]> => {
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
                let text = isUser ? message.text : stripHiddenParts(message.text);

                if (isUser) {
                    const parsed = parseDocumentBlocks(text);
                    if (parsed.documents.length === 0) {
                        const docs = await loadMessageDocuments(message);
                        if (docs.length > 0) {
                            text = buildPromptWithDocuments(text, docs);
                        }
                    }

                    const imageCount = (message.attachments ?? []).filter(
                        (attachment) => attachment.kind === "image",
                    ).length;
                    if (imageCount > 0) {
                        text += `\n\n[${imageCount} attachment${imageCount === 1 ? "" : "s"} attached]`;
                    }
                }

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
        [
            approxTokens,
            loadMessageDocuments,
            slicePathUntil,
            stripHiddenParts,
        ],
    );


    const handleNewChat = useCallback(() => {
        setCurrentSessionId(undefined);
        currentSessionIdRef.current = undefined;
        setAllMessages([]);
        setInput("");
        setEditingMessage(null);
        setPendingDocuments([]);
        setPendingImages([]);
        setStreamingParentId(null);
        setStreamingText("");
        setIsGenerating(false);
        setIsDraftSession(true);
        isDraftSessionRef.current = true;
        updateRouteSession(undefined, true);
        if (isSmall) setDrawerOpen(false);
        focusInput();
    }, [focusInput, isSmall, updateRouteSession]);

    const handleSelectSession = useCallback(
        (sessionId: string) => {
            setCurrentSessionId(sessionId);
            currentSessionIdRef.current = sessionId;
            setIsDraftSession(false);
            isDraftSessionRef.current = false;
            updateRouteSession(sessionId);
            if (isSmall) setDrawerOpen(false);
            focusInput();
        },
        [focusInput, isSmall, updateRouteSession],
    );

    const handleDeleteSession = useCallback(
        async (sessionId: string) => {
            if (!chatKey) return;
            await deleteSession(sessionId, chatKey);
            await refreshSessions();
            void syncChat(chatKey);
            if (sessionId === currentSessionId) {
                const refreshed = await listSessions(chatKey);
                const nextSession = refreshed[0];
                if (nextSession) {
                    setCurrentSessionId(nextSession.sessionUuid);
                    updateRouteSession(nextSession.sessionUuid, true);
                } else {
                    setCurrentSessionId(undefined);
                    setAllMessages([]);
                    updateRouteSession(undefined, true);
                }
            }
        },
        [
            chatKey,
            currentSessionId,
            refreshSessions,
            syncChat,
            updateRouteSession,
        ],
    );

    const requestDeleteSession = useCallback((sessionId: string) => {
        setDeleteSessionId(sessionId);
    }, []);

    const handleConfirmDeleteSession = useCallback(async () => {
        if (!deleteSessionId) return;
        await handleDeleteSession(deleteSessionId);
        setDeleteSessionId(null);
    }, [deleteSessionId, handleDeleteSession]);

    const handleCancelDeleteSession = useCallback(() => {
        setDeleteSessionId(null);
    }, []);

    const handleEditMessage = useCallback(
        async (message: ChatMessage) => {
            const parsed = parseDocumentBlocks(message.text);
            setEditingMessage(message);
            setInput(parsed.text);

            if (parsed.documents.length > 0) {
                setPendingDocuments(parsed.documents);
                return;
            }

            const attachments = message.attachments ?? [];
            if (attachments.length === 0) {
                setPendingDocuments([]);
                return;
            }

            if (!chatKey) {
                showMiniDialog({
                    title: "Attachment error",
                    message:
                        "Attachments are unavailable until encryption is ready.",
                });
                setPendingDocuments([]);
                return;
            }

            try {
                const docs = await Promise.all(
                    attachments.map(async (attachment) => {
                        await downloadAttachment(attachment.id);
                        const bytes = await readDecryptedAttachmentBytes(
                            attachment.id,
                            chatKey,
                            message.sessionUuid,
                        );
                        return {
                            id: attachment.id,
                            name: attachment.name,
                            text: new TextDecoder().decode(bytes),
                            size: bytes.length,
                        } satisfies DocumentAttachment;
                    }),
                );
                setPendingDocuments(docs);
            } catch (error) {
                log.error("Failed to load attachment contents", error);
                showMiniDialog({
                    title: "Attachment error",
                    message:
                        "We could not load attachment contents for editing.",
                });
                setPendingDocuments([]);
            }
        },
        [
            chatKey,
            downloadAttachment,
            readDecryptedAttachmentBytes,
            showMiniDialog,
        ],
    );

    const handleCancelEdit = useCallback(() => {
        setEditingMessage(null);
        setInput("");
        setPendingDocuments([]);
        setPendingImages([]);
    }, []);

    const showToast = useCallback((attributes: NotificationAttributes) => {
        setSyncNotification(attributes);
        setSyncNotificationOpen(true);
    }, []);

    const handleCopyMessage = useCallback(
        async (text: string) => {
            try {
                await navigator.clipboard.writeText(text);
                showToast({
                    title: "Copied to clipboard.",
                    color: "inherit",
                    autoHideDuration: 2000,
                });
            } catch (error) {
                log.error("Failed to copy message", error);
                showToast({
                    title: "Copy failed.",
                    color: "inherit",
                    autoHideDuration: 3000,
                });
            }
        },
        [showToast],
    );

    const handleDownloadAttachment = useCallback(
        async (message: ChatMessage, attachment: ChatAttachment) => {
            if (!chatKey) return;

            try {
                await downloadAttachment(attachment.id);
                const bytes = await readDecryptedAttachmentBytes(
                    attachment.id,
                    chatKey,
                    message.sessionUuid,
                );

                const filename =
                    attachment.name || `attachment-${attachment.id}`;

                if (attachment.kind === "document") {
                    const text = new TextDecoder().decode(bytes);
                    saveStringAsFile(text, filename);
                    return;
                }

                const blob = new Blob([bytes]);
                const url = URL.createObjectURL(blob);
                saveAsFileAndRevokeObjectURL(url, filename);
            } catch (error) {
                log.error("Failed to download attachment", error);
                showMiniDialog({
                    title: "Attachment download failed",
                    message:
                        "We could not download this attachment. Please try again.",
                });
            }
        },
        [
            chatKey,
            downloadAttachment,
            readDecryptedAttachmentBytes,
            saveAsFileAndRevokeObjectURL,
            saveStringAsFile,
            showMiniDialog,
        ],
    );

    const flushStreamingText = useCallback(() => {
        if (streamingFlushTimerRef.current) {
            window.clearTimeout(streamingFlushTimerRef.current);
            streamingFlushTimerRef.current = null;
        }
        setStreamingText(streamingBufferRef.current);
    }, []);

    const scheduleStreamingFlush = useCallback(() => {
        if (streamingFlushTimerRef.current) return;
        streamingFlushTimerRef.current = window.setTimeout(() => {
            setStreamingText(streamingBufferRef.current);
            streamingFlushTimerRef.current = null;
        }, 50);
    }, []);

    const handleStopGeneration = useCallback(() => {
        const jobId = currentJobIdRef.current;
        pendingCancelRef.current = true;
        stopRequestedRef.current = true;
        generationTokenRef.current += 1;

        const last = lastGenerationRef.current;
        if (last?.previousSelection) {
            updateBranchSelectionState(
                last.parentMessageUuid,
                last.previousSelection,
            );
        }

        setIsGenerating(false);
        setIsDownloading(false);
        setStreamingParentId(null);
        streamingBufferRef.current = "";
        setStreamingText("");
        currentJobIdRef.current = null;

        const provider = providerRef.current;
        if (provider) {
            provider.cancelGeneration(jobId ?? -1);
            return;
        }

        void (async () => {
            try {
                const ensured = await ensureProvider();
                ensured.cancelGeneration(jobId ?? -1);
            } catch (error) {
                log.error("Failed to cancel generation", error);
            }
        })();
    }, [ensureProvider, updateBranchSelectionState]);

    const startGeneration = useCallback(
        async ({
            promptText,
            parentMessageUuid,
            historyPath,
            stopAtMessageUuid,
            resetContext = false,
            sessionUuid,
            imagePaths,
            mediaMarker,
        }: {
            promptText: string;
            parentMessageUuid: string;
            historyPath: ChatMessage[];
            stopAtMessageUuid?: string | null;
            resetContext?: boolean;
            sessionUuid?: string;
            imagePaths?: string[];
            mediaMarker?: string;
        }) => {
            const activeSessionId =
                sessionUuid ?? currentSessionIdRef.current ?? currentSessionId;
            if (!chatKey || !activeSessionId) return;

            if (pendingCancelRef.current) {
                pendingCancelRef.current = false;
            }
            stopRequestedRef.current = false;

            const generationToken = generationTokenRef.current + 1;
            generationTokenRef.current = generationToken;

            const isActiveGeneration = () =>
                generationTokenRef.current === generationToken &&
                currentSessionIdRef.current === activeSessionId;

            const provider = await ensureProvider();
            const settings = getModelSettings();
            const { contextSize, maxTokens } =
                provider.resolveRuntimeSettings(settings);

            if (!isActiveGeneration()) {
                return;
            }

            const previousSelection = branchSelections[parentMessageUuid];
            lastGenerationRef.current = {
                parentMessageUuid,
                previousSelection,
            };

            updateBranchSelectionState(
                parentMessageUuid,
                STREAMING_SELECTION_KEY,
                false,
            );
            setStreamingParentId(parentMessageUuid);
            setStreamingText("");
            streamingBufferRef.current = "";
            setIsGenerating(true);
            currentJobIdRef.current = null;

            let buffer = "";
            let errorMessage: string | null = null;

            try {
                await provider.ensureModelReady(settings);
                setLoadedModelName(provider.getCurrentModel()?.name ?? null);
                setIsDownloading(false);
                setDownloadStatus({ percent: 100, status: "Ready" });

                if (!isActiveGeneration()) {
                    return;
                }

                if (resetContext) {
                    await provider.resetContext(contextSize);
                }

                const history =
                    (await buildHistory(
                        historyPath,
                        promptText,
                        contextSize,
                        maxTokens,
                        stopAtMessageUuid,
                    )) ?? [];

                const messages: LlmMessage[] = [
                    { role: "system", content: CHAT_SYSTEM_PROMPT },
                    ...history,
                    { role: "user", content: promptText },
                ];

                if (pendingCancelRef.current || stopRequestedRef.current) {
                    pendingCancelRef.current = false;
                    stopRequestedRef.current = false;
                    provider.cancelGeneration(-1);
                    if (previousSelection) {
                        updateBranchSelectionState(
                            parentMessageUuid,
                            previousSelection,
                        );
                    }
                    setIsGenerating(false);
                    setIsDownloading(false);
                    setStreamingParentId(null);
                    streamingBufferRef.current = "";
                    setStreamingText("");
                    currentJobIdRef.current = null;
                    return;
                }

                const hasImages =
                    (imagePaths?.length ?? 0) > 0 &&
                    provider.getBackendKind() === "tauri";
                const mmprojPath = hasImages
                    ? provider.getCurrentMmprojPath()
                    : undefined;
                if (hasImages && !mmprojPath) {
                    throw new Error("MMProj model not available");
                }

                await provider.generateChatStream(
                    {
                        messages,
                        imagePaths: hasImages ? imagePaths : undefined,
                        mmprojPath,
                        mediaMarker: hasImages
                            ? mediaMarker ?? MEDIA_MARKER
                            : undefined,
                        maxTokens,
                        temperature: 0.7,
                        topP: 0.9,
                    },
                    (event: GenerateEvent) => {
                        if (!isActiveGeneration()) {
                            return;
                        }
                        if (event.type === "text") {
                            if (!currentJobIdRef.current) {
                                currentJobIdRef.current = event.job_id;
                                if (pendingCancelRef.current) {
                                    pendingCancelRef.current = false;
                                    provider.cancelGeneration(event.job_id);
                                    return;
                                }
                            }
                            buffer += event.text;
                            streamingBufferRef.current = buffer;
                            scheduleStreamingFlush();
                        } else if (event.type === "error") {
                            errorMessage = event.message;
                        } else if (event.type === "done") {
                            currentJobIdRef.current = event.summary.job_id;
                        }
                    },
                );

                if (!isActiveGeneration()) {
                    return;
                }

                flushStreamingText();

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
                    activeSessionId,
                    "assistant",
                    buffer.replace(/\u0000/g, ""),
                    chatKey,
                    parentMessageUuid,
                );

                updateBranchSelectionState(parentMessageUuid, assistantUuid);

                await refreshSessions();
                await refreshMessages(activeSessionId);
                void syncChat(chatKey);
                void maybeGenerateSessionTitle({
                    sessionUuid: activeSessionId,
                    assistantMessageUuid: assistantUuid,
                    wasInterrupted: !!errorMessage,
                });
            } catch (error) {
                if (!isActiveGeneration()) {
                    return;
                }
                const message = formatErrorMessage(error);
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
                if (!isActiveGeneration()) {
                    return;
                }
                setIsGenerating(false);
                setIsDownloading(false);
                setStreamingParentId(null);
                streamingBufferRef.current = "";
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
            syncChat,
            scheduleStreamingFlush,
            flushStreamingText,
            maybeGenerateSessionTitle,
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
                sessionUuid: currentSessionId ?? undefined,
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
    }, [isSmall]);

    const handleCollapseDrawer = useCallback(() => {
        handleCloseDrawer();
    }, [handleCloseDrawer]);

    const openSettingsModal = useCallback(
        () => setShowSettingsModal(true),
        [],
    );
    const closeSettingsModal = useCallback(
        () => setShowSettingsModal(false),
        [],
    );

    const openDeveloperMenu = useCallback(() => {
        if (!DEVELOPER_SETTINGS_ENABLED) return;
        setShowDeveloperMenu(true);
    }, []);
    const closeDeveloperMenu = useCallback(
        () => setShowDeveloperMenu(false),
        [],
    );

    const handleLogoClick = useCallback(() => {
        if (typeof window === "undefined") return;
        if (!DEVELOPER_SETTINGS_ENABLED) return;
        if (logoClickTimeoutRef.current) {
            window.clearTimeout(logoClickTimeoutRef.current);
        }
        logoClickCountRef.current += 1;
        if (logoClickCountRef.current >= 5) {
            logoClickCountRef.current = 0;
            openDeveloperMenu();
            return;
        }
        logoClickTimeoutRef.current = window.setTimeout(() => {
            logoClickCountRef.current = 0;
        }, 1500);
    }, [openDeveloperMenu]);

    const markUserScrollIntent = useCallback(() => {
        userScrollIntentRef.current = true;
        if (userScrollTimeoutRef.current) {
            window.clearTimeout(userScrollTimeoutRef.current);
        }
        userScrollTimeoutRef.current = window.setTimeout(() => {
            userScrollIntentRef.current = false;
            userScrollTimeoutRef.current = null;
        }, 200);
    }, []);

    const handleScroll = useCallback(() => {
        const container = scrollContainerRef.current;
        if (!container) return;
        const distance =
            container.scrollHeight -
            container.scrollTop -
            container.clientHeight;
        const atBottom = distance <= 120;
        const previousTop = lastScrollTopRef.current;
        const currentTop = container.scrollTop;
        lastScrollTopRef.current = currentTop;

        if (
            currentTop < previousTop - 4 &&
            userScrollIntentRef.current &&
            !atBottom
        ) {
            setStickToBottom(false);
            return;
        }

        if (atBottom) {
            setStickToBottom(true);
        }
    }, []);

    const handleOpenSessionSearch = useCallback(() => {
        setShowSessionSearch(true);
    }, []);
    const handleCloseSessionSearch = useCallback(() => {
        setSessionSearch("");
        setShowSessionSearch(false);
    }, []);

    const openDevSettings = useCallback(() => setShowDevSettings(true), []);
    const closeDevSettings = useCallback(() => setShowDevSettings(false), []);

    const saveLogs = useCallback(async () => {
        log.info("Saving logs");
        const electron = globalThis.electron;
        if (electron) {
            await electron.openLogDirectory();
            return;
        }

        if (isTauriRuntime) {
            try {
                const filename = `ensu-web-logs-${Date.now()}.txt`;
                const path = await save({
                    defaultPath: filename,
                    filters: [
                        {
                            name: "Logs",
                            extensions: ["txt"],
                        },
                    ],
                });
                if (!path) return;
                await writeTextFile({ path, contents: savedLogs() });
                return;
            } catch (error) {
                log.error("Failed to export logs", error);
                showMiniDialog({
                    title: "Save logs failed",
                    message:
                        "We could not save the log file. Please check the console for errors.",
                });
                return;
            }
        }

        saveStringAsFile(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
    }, [isTauriRuntime, showMiniDialog]);

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
            setMmprojUrl(allowMmproj ? mmproj ?? "" : "");
            setModelUrlError(null);
            setMmprojError(null);
        },
        [allowMmproj],
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

    const handleImageSelect = useCallback(
        (files: File[]) => {
            closeAttachmentMenu();
            const images = files.map((file) => ({
                id: createAttachmentId(),
                name: file.name.replace(/\0/g, ''),
                size: file.size,
                file,
            }));
            if (images.length) {
                setPendingImages((prev) => [...prev, ...images]);
            }
        },
        [closeAttachmentMenu],
    );

    const handleImageCancel = useCallback(() => {
        closeAttachmentMenu();
    }, [closeAttachmentMenu]);

    const {
        getInputProps: getImageInputProps,
        openSelector: openImageSelector,
    } = useFileInput({
        directory: false,
        accept: "image/*",
        onSelect: handleImageSelect,
        onCancel: handleImageCancel,
    });

    const openAttachmentMenu = useCallback(() => {
        closeAttachmentMenu();
        if (showImageAttachment) {
            openImageSelector();
            return;
        }
        openDocumentSelector();
    }, [closeAttachmentMenu, openDocumentSelector, openImageSelector, showImageAttachment]);

    const handleAttachmentChoice = useCallback(
        (choice: "image" | "document") => {
            if (choice === "image") {
                closeAttachmentMenu();
                openImageSelector();
            } else {
                closeAttachmentMenu();
                openDocumentSelector();
            }
        },
        [closeAttachmentMenu, openDocumentSelector, openImageSelector],
    );

    const removePendingDocument = useCallback((id: string) => {
        setPendingDocuments((prev) => prev.filter((doc) => doc.id !== id));
    }, []);

    const removePendingImage = useCallback((id: string) => {
        setPendingImages((prev) => prev.filter((img) => img.id !== id));
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
        if (!SIGN_IN_ENABLED) {
            setShowComingSoon(true);
            return;
        }
        void router.push("/login");
    }, [router]);

    const handleSend = useCallback(async () => {
        const trimmed = input.trim();
        const hasDocuments = pendingDocuments.length > 0;
        const hasImages = pendingImages.length > 0;
        if (!chatKey) {
            showMiniDialog({
                title: "Chat unavailable",
                message:
                    "Encryption is still initializing. Please try again in a moment.",
            });
            return;
        }
        if (!trimmed && !hasDocuments && !hasImages) {
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

        const container = scrollContainerRef.current;
        if (container) {
            setStickToBottom(true);
            container.scrollTo({
                top: container.scrollHeight,
                behavior: "auto",
            });
        } else {
            setStickToBottom(true);
        }

        let activeSessionId = currentSessionId;
        if (!activeSessionId) {
            activeSessionId = await createSession(chatKey);
            setCurrentSessionId(activeSessionId);
            currentSessionIdRef.current = activeSessionId;
            setIsDraftSession(false);
            isDraftSessionRef.current = false;
            updateRouteSession(activeSessionId, true);
            await refreshSessions();
        }

        const messageText = buildPromptWithDocuments(
            trimmed.replace(/\u0000/g, ""),
            pendingDocuments,
        );
        let promptText = messageText;
        let inferenceImagePaths: string[] = [];

        let attachments: ChatAttachment[] = [];
        if (pendingDocuments.length > 0 || pendingImages.length > 0) {
            try {
                const encoder = new TextEncoder();
                const documentAttachments = await Promise.all(
                    pendingDocuments.map(async (doc) => {
                        const bytes = encoder.encode(doc.text);
                        await storeEncryptedAttachmentBytes(
                            doc.id,
                            bytes,
                            chatKey,
                            activeSessionId,
                        );
                        return {
                            id: doc.id,
                            kind: "document",
                            name: doc.name.replace(/\0/g, ''),
                            size: bytes.length,
                        } satisfies ChatAttachment;
                    }),
                );
                const imageAttachments = await Promise.all(
                    pendingImages.map(async (img) => {
                        const bytes = new Uint8Array(
                            await img.file.arrayBuffer(),
                        );
                        await storeEncryptedAttachmentBytes(
                            img.id,
                            bytes,
                            chatKey,
                            activeSessionId,
                        );
                        const previewUrl = URL.createObjectURL(
                            new Blob([bytes]),
                        );
                        attachmentPreviewUrlsRef.current[img.id] = previewUrl;
                        setAttachmentPreviews((prev) => ({
                            ...prev,
                            [img.id]: previewUrl,
                        }));
                        return {
                            id: img.id,
                            kind: "image",
                            name: img.name.replace(/\0/g, ''),
                            size: img.size,
                        } satisfies ChatAttachment;
                    }),
                );
                attachments = [...documentAttachments, ...imageAttachments];
            } catch (error) {
                log.error("Failed to store attachments", error);
                showMiniDialog({
                    title: "Attachment error",
                    message:
                        "We could not attach the files. Please try again.",
                });
                return;
            }
        }

        if (pendingImages.length > 0) {
            try {
                inferenceImagePaths = await writeInferenceImages(pendingImages);
            } catch (error) {
                log.error("Failed to prepare images for inference", error);
                showMiniDialog({
                    title: "Attachment error",
                    message:
                        "We could not prepare the images for inference. Please try again.",
                });
                return;
            }
        }

        promptText = buildPromptWithImages(
            messageText,
            inferenceImagePaths.length,
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
                    activeSessionId,
                    "self",
                    messageText,
                    chatKey,
                    parentUuid,
                    attachments,
                );

                updateBranchSelectionState(selectionKey, newUserUuid);
                setEditingMessage(null);
                setPendingDocuments([]);
                setPendingImages([]);

                await refreshMessages(activeSessionId);
                void syncChat(chatKey);

                await startGeneration({
                    promptText,
                    parentMessageUuid: newUserUuid,
                    historyPath,
                    sessionUuid: activeSessionId,
                    imagePaths:
                        inferenceImagePaths.length > 0
                            ? inferenceImagePaths
                            : undefined,
                });
                return;
            }

            const basePath = messageState.path;
            const leaf = basePath[basePath.length - 1];
            const parentUuid = leaf?.messageUuid;
            const selectionKey = parentUuid ?? ROOT_SELECTION_KEY;

            const userUuid = await addMessage(
                activeSessionId,
                "self",
                messageText,
                chatKey,
                parentUuid,
                attachments,
            );

            updateBranchSelectionState(selectionKey, userUuid);
            setPendingDocuments([]);
            setPendingImages([]);

            await refreshMessages(activeSessionId);
            void syncChat(chatKey);

            await startGeneration({
                promptText,
                parentMessageUuid: userUuid,
                historyPath: basePath,
                sessionUuid: activeSessionId,
                imagePaths:
                    inferenceImagePaths.length > 0
                        ? inferenceImagePaths
                        : undefined,
            });
        } catch (error) {
            log.error("Failed to store chat message", error);
        } finally {
            await cleanupInferenceImages(inferenceImagePaths);
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
        pendingImages,
        refreshMessages,
        refreshSessions,
        showMiniDialog,
        slicePathUntil,
        startGeneration,
        writeInferenceImages,
        cleanupInferenceImages,
        storeEncryptedAttachmentBytes,
        syncChat,
        updateBranchSelectionState,
        updateRouteSession,
        formatErrorMessage,
    ]);

    useEffect(() => {
        return () => {
            if (streamingFlushTimerRef.current) {
                window.clearTimeout(streamingFlushTimerRef.current);
            }
            if (downloadProgressTimerRef.current) {
                window.clearTimeout(downloadProgressTimerRef.current);
            }
            if (userScrollTimeoutRef.current) {
                window.clearTimeout(userScrollTimeoutRef.current);
            }
        };
    }, []);

    const sidebar = (
        <Stack
            sx={{ width: "100%", height: "100%", bgcolor: "background.default" }}
        >
            <Box
                sx={{
                    px: 2.5,
                    height: 64,
                    minHeight: 64,
                    display: "flex",
                    alignItems: "center",
                }}
            >
                <Stack
                    direction="row"
                    sx={{
                        gap: 1,
                        alignItems: "center",
                        width: "100%",
                    }}
                >
                    <Stack sx={{ flex: 1, gap: 1 }}>
                        <Typography
                            component="button"
                            onClick={handleNewChat}
                            variant="h2"
                            sx={{
                                fontFamily: '"Montserrat", sans-serif',
                                fontWeight: 600,
                                letterSpacing: "1px",
                                textTransform: "lowercase",
                                border: "none",
                                padding: 0,
                                background: "transparent",
                                cursor: "pointer",
                                color: "inherit",
                                textAlign: "left",
                                alignSelf: "flex-start",
                                userSelect: "none",
                                WebkitUserSelect: "none",
                                MozUserSelect: "none",
                                msUserSelect: "none",
                                outline: "none",
                            }}
                        >
                            e
                        </Typography>
                    </Stack>
                    <Stack direction="row" sx={{ gap: 0.5 }}>
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

                    <List
                        sx={{
                            flex: 1,
                            overflowY: "auto",
                            px: 1,
                            overscrollBehaviorY: "contain",
                        }}
                    >
                        <Stack
                            direction="row"
                            sx={{
                                alignItems: "center",
                                justifyContent: "flex-start",
                                gap: 1,
                                my: 1,
                                px: 1,
                                width: "100%",
                            }}
                        >
                            {showSessionSearch ? (
                                <>
                                    <Box
                                        sx={{
                                            flex: 1,
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "flex-start",
                                            gap: 1,
                                            px: 1.5,
                                            height: 40,
                                            borderRadius: 2,
                                            bgcolor: "fill.faint",
                                            textAlign: "left",
                                        }}
                                    >
                                        <HugeiconsIcon
                                            icon={Search01Icon}
                                            {...tinyIconProps}
                                        />
                                        <InputBase
                                            placeholder="Search chats"
                                            autoFocus
                                            value={sessionSearch}
                                            onChange={(event) =>
                                                setSessionSearch(
                                                    event.target.value,
                                                )
                                            }
                                            inputProps={{
                                                style: { textAlign: "left" },
                                            }}
                                            sx={{
                                                flex: 1,
                                                color: "text.base",
                                                fontFamily:
                                                    '"Inter", sans-serif',
                                                fontSize: "13px",
                                                textAlign: "left",
                                                "& input": {
                                                    textAlign: "left",
                                                },
                                            }}
                                        />
                                    </Box>
                                    <IconButton
                                        aria-label="Close search"
                                        sx={drawerIconButtonSx}
                                        onClick={handleCloseSessionSearch}
                                    >
                                        <HugeiconsIcon
                                            icon={Cancel01Icon}
                                            {...tinyIconProps}
                                        />
                                    </IconButton>
                                </>
                            ) : (
                                <>
                                    <Button
                                        onClick={handleOpenSessionSearch}
                                        variant="outlined"
                                        startIcon={
                                            <HugeiconsIcon
                                                icon={Search01Icon}
                                                {...tinyIconProps}
                                            />
                                        }
                                        sx={{
                                            flex: 1,
                                            minWidth: 0,
                                            height: 40,
                                            minHeight: 40,
                                            px: 1.5,
                                            textTransform: "none",
                                            fontWeight: 600,
                                            fontSize: "13px",
                                            whiteSpace: "nowrap",
                                            textOverflow: "ellipsis",
                                            overflow: "hidden",
                                            borderRadius: 2,
                                            borderColor: "divider",
                                            color: "text.base",
                                            bgcolor: "fill.faint",
                                            flexWrap: "nowrap",
                                            justifyContent: "flex-start",
                                            textAlign: "left",
                                            "& .MuiButton-startIcon": {
                                                marginRight: 0.75,
                                                marginLeft: 0,
                                            },
                                            "&:hover": {
                                                bgcolor: "fill.faintHover",
                                                borderColor: "divider",
                                            },
                                        }}
                                    >
                                        <Box
                                            component="span"
                                            sx={{
                                                whiteSpace: "nowrap",
                                                overflow: "hidden",
                                                textOverflow: "ellipsis",
                                            }}
                                        >
                                            Search
                                        </Box>
                                    </Button>
                                    {isLoggedIn && (
                                        <Button
                                            onClick={() => {
                                                void syncNow({
                                                    showToast: true,
                                                });
                                            }}
                                            variant="outlined"
                                            startIcon={
                                                <HugeiconsIcon
                                                    icon={ArrowReloadHorizontalIcon}
                                                    {...tinyIconProps}
                                                />
                                            }
                                            sx={{
                                                flex: 1,
                                                minWidth: 0,
                                                height: 40,
                                                minHeight: 40,
                                                px: 1.5,
                                                textTransform: "none",
                                                fontWeight: 600,
                                                fontSize: "13px",
                                                whiteSpace: "nowrap",
                                                textOverflow: "ellipsis",
                                                overflow: "hidden",
                                                borderRadius: 2,
                                                borderColor: "divider",
                                                color: "text.base",
                                                bgcolor: "fill.faint",
                                                flexWrap: "nowrap",
                                                "& .MuiButton-startIcon": {
                                                    marginRight: 0.75,
                                                    marginLeft: 0,
                                                },
                                                "&:hover": {
                                                    bgcolor: "fill.faintHover",
                                                    borderColor: "divider",
                                                },
                                            }}
                                        >
                                            <Box
                                                component="span"
                                                sx={{
                                                    whiteSpace: "nowrap",
                                                    overflow: "hidden",
                                                    textOverflow: "ellipsis",
                                                }}
                                            >
                                                Sync
                                            </Box>
                                        </Button>
                                    )}
                                    <Tooltip title="New Chat">
                                        <IconButton
                                            aria-label="New Chat"
                                            onClick={handleNewChat}
                                            sx={drawerIconButtonSx}
                                        >
                                            <HugeiconsIcon
                                                icon={PlusSignIcon}
                                                {...tinyIconProps}
                                            />
                                        </IconButton>
                                    </Tooltip>
                                </>
                            )}
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
                                                            '"Inter", sans-serif',
                                                    }}
                                                >
                                                    {session.title}
                                                </Typography>
                                                <Typography
                                                    variant="mini"
                                                    sx={{
                                                        color: "text.muted",
                                                        fontFamily:
                                                            '"Inter", sans-serif',
                                                        display: "-webkit-box",
                                                        WebkitLineClamp: 1,
                                                        WebkitBoxOrient:
                                                            "vertical",
                                                        overflow: "hidden",
                                                    }}
                                                >
                                                    {session.lastMessagePreview ??
                                                        "Nothing here"}
                                                </Typography>
                                            </Box>
                                            <IconButton
                                                aria-label="Delete chat"
                                                sx={actionButtonSx}
                                                onClick={(event) => {
                                                    event.stopPropagation();
                                                    requestDeleteSession(
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
                        <Stack sx={{ p: 1 }}>
                            <ListItemButton
                                onClick={openSettingsModal}
                                sx={{
                                    alignItems: "center",
                                    gap: 1,
                                    px: 2,
                                    py: 1.25,
                                    width: "100%",
                                    borderRadius: 2,
                                    border: "1px solid",
                                    borderColor: "divider",
                                    bgcolor: "background.paper",
                                    boxShadow:
                                        "0px 10px 24px rgba(0, 0, 0, 0.08)",
                                    "&:hover": {
                                        backgroundColor: "fill.faintHover",
                                    },
                                }}
                            >
                                <Typography
                                    variant="small"
                                    sx={{ flex: 1, fontWeight: 600 }}
                                >
                                    {isLoggedIn
                                        ? savedLocalUser()?.email ?? "Account"
                                        : "Settings"}
                                </Typography>
                                <HugeiconsIcon
                                    icon={ArrowRight01Icon}
                                    {...smallIconProps}
                                />
                            </ListItemButton>
                        </Stack>
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
                    fontFamily: '"Inter", sans-serif',
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
                                backgroundColor: "background.default",
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
                    ref={chatViewportRef}
                    sx={{
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        height: "100%",
                        position: "relative",
                    }}
                >
                    <NavbarBase
                        sx={{
                            justifyContent: "space-between",
                            px: 2,
                            height: 64,
                            minHeight: 64,
                            bgcolor: isDesktopOverlay
                                ? "transparent"
                                : "background.paper",
                            borderBottom: isDesktopOverlay ? "none" : undefined,
                            position: isDesktopOverlay ? "absolute" : "relative",
                            top: isDesktopOverlay ? 0 : undefined,
                            left: isDesktopOverlay ? 0 : undefined,
                            right: isDesktopOverlay ? 0 : undefined,
                            zIndex: isDesktopOverlay ? 10 : undefined,
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
                            <Stack sx={{ gap: 0 }}>
                                <Box
                                    component="button"
                                    onClick={handleLogoClick}
                                    onMouseDown={(event) => event.preventDefault()}
                                    onDoubleClick={(event) => event.preventDefault()}
                                    onPointerDown={(event) => event.preventDefault()}
                                    sx={{
                                        border: "none",
                                        padding: 0,
                                        background: "transparent",
                                        cursor: "pointer",
                                        display: "flex",
                                        alignItems: "center",
                                        userSelect: "none",
                                        WebkitUserSelect: "none",
                                        MozUserSelect: "none",
                                        msUserSelect: "none",
                                        outline: "none",
                                    }}
                                >
                                    <Box
                                        component="img"
                                        src={logoSrc}
                                        alt="ensu"
                                        draggable={false}
                                        sx={{
                                            height: 16,
                                            width: "auto",
                                            filter: logoFilter,
                                        }}
                                    />
                                </Box>
                            </Stack>
                        </Stack>
                        {!isLoggedIn && (
                            <Button
                                onClick={openLoginFromChat}
                                color="inherit"
                                variant="text"
                                sx={{
                                    textTransform: "none",
                                    fontWeight: 600,
                                    fontSize: "13px",
                                    color: "text.base",
                                    py: 0.75,
                                }}
                            >
                                Sign In
                            </Button>
                        )}
                    </NavbarBase>

                    <Box
                        ref={scrollContainerRef}
                        onScroll={handleScroll}
                        onWheel={markUserScrollIntent}
                        onTouchMove={markUserScrollIntent}
                        sx={{
                            flex: 1,
                            overflowY: "auto",
                            px: { xs: 2, md: 4 },
                            pt: isDesktopOverlay
                                ? "calc(64px + 16px)"
                                : 2,
                            pb: 12,
                            bgcolor: "background.paper",
                            overscrollBehaviorY: "contain",
                        }}
                    >
                        <Box
                            sx={{
                                width: "100%",
                                maxWidth: 900,
                                mx: "auto",
                            }}
                        >
                            {displayMessages.length === 0 ? (
                                <Stack
                                    sx={{
                                        gap: 1,
                                        height: "100%",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        textAlign: "center",
                                    }}
                                >
                                    <Typography variant="h2">Welcome</Typography>
                                    <Typography
                                        variant="small"
                                        sx={{ color: "text.muted" }}
                                    >
                                        Type a message to start chatting
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
                                    const attachments =
                                        message.attachments ?? [];
                                    const imageAttachments = attachments.filter(
                                        (attachment) =>
                                            attachment.kind === "image",
                                    );
                                    const documentAttachments =
                                        attachments.filter(
                                            (attachment) =>
                                                attachment.kind ===
                                                "document",
                                        );
                                    const parsedDocuments = isSelf
                                        ? parseDocumentBlocks(message.text)
                                        : { text: message.text, documents: [] };
                                    const documentCount =
                                        documentAttachments.length > 0
                                            ? documentAttachments.length
                                            : parsedDocuments.documents.length;
                                    const imageCount = imageAttachments.length;
                                    const fallbackText = imageCount
                                        ? "Attached images"
                                        : documentCount > 0
                                            ? "Attached documents"
                                            : "";
                                    const displayText = isSelf
                                        ? parsedDocuments.text || fallbackText
                                        : message.text || fallbackText;
                                    const copyText = isSelf
                                        ? displayText
                                        : stripHiddenParts(message.text);
                                    const showAttachments =
                                        !isStreaming &&
                                        documentAttachments.length > 0;
                                    const imagePreviewItems =
                                        imageAttachments
                                            .map((attachment) => ({
                                                attachment,
                                                url: attachmentPreviews[
                                                    attachment.id
                                                ],
                                            }))
                                            .filter(
                                                (item): item is {
                                                    attachment: ChatAttachment;
                                                    url: string;
                                                } =>
                                                    typeof item.url ===
                                                    "string",
                                            );
                                    const showLoadingPlaceholder =
                                        !isSelf &&
                                        isStreaming &&
                                        !displayText.trim();
                                    const dots = ".".repeat(loadingDots);
                                    return (
                                        <Box
                                            key={message.messageUuid}
                                            sx={{
                                                display: "flex",
                                                justifyContent: isSelf
                                                    ? "flex-end"
                                                    : "flex-start",
                                                pl: isSelf ? "80px" : 0,
                                                pr: isSelf ? 0 : "80px",
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
                                                {isSelf ? (
                                                    <Box
                                                        sx={{
                                                            bgcolor: userBubbleBackground,
                                                            borderRadius: "18px",
                                                            px: "12px",
                                                            py: "12px",
                                                            alignSelf:
                                                                "flex-end",
                                                            maxWidth: "100%",
                                                        }}
                                                    >
                                                        {imagePreviewItems.length > 0 && (
                                                            <Box
                                                                sx={{
                                                                    display:
                                                                        "grid",
                                                                    gridTemplateColumns:
                                                                        "repeat(2, minmax(0, 1fr))",
                                                                    gap: 1,
                                                                    mb: 1,
                                                                }}
                                                            >
                                                                {imagePreviewItems.map(
                                                                    ({
                                                                        attachment,
                                                                        url,
                                                                    }) => (
                                                                        <Box
                                                                            key={attachment.id}
                                                                            component="img"
                                                                            src={url}
                                                                            alt={
                                                                                attachment.name ??
                                                                                "Image"
                                                                            }
                                                                            sx={{
                                                                                width: "100%",
                                                                                height: 140,
                                                                                objectFit:
                                                                                    "cover",
                                                                                borderRadius: 2,
                                                                                cursor:
                                                                                    "pointer",
                                                                            }}
                                                                            onClick={() => {
                                                                                void handleDownloadAttachment(
                                                                                    message,
                                                                                    attachment,
                                                                                );
                                                                            }}
                                                                        />
                                                                    ),
                                                                )}
                                                            </Box>
                                                        )}
                                                        <Typography
                                                            variant="message"
                                                            sx={userMessageTextSx}
                                                        >
                                                            {displayText}
                                                        </Typography>
                                                    </Box>
                                                ) : (
                                                    <Box
                                                        sx={{
                                                            px: "8px",
                                                            py: "12px",
                                                            alignSelf:
                                                                "stretch",
                                                            width: "100%",
                                                            ...(isStreaming
                                                                ? streamingMessageSx
                                                                : {}),
                                                        }}
                                                    >
                                                        {imagePreviewItems.length > 0 && (
                                                            <Box
                                                                sx={{
                                                                    display:
                                                                        "grid",
                                                                    gridTemplateColumns:
                                                                        "repeat(2, minmax(0, 1fr))",
                                                                    gap: 1,
                                                                    mb: 1,
                                                                }}
                                                            >
                                                                {imagePreviewItems.map(
                                                                    ({
                                                                        attachment,
                                                                        url,
                                                                    }) => (
                                                                        <Box
                                                                            key={attachment.id}
                                                                            component="img"
                                                                            src={url}
                                                                            alt={
                                                                                attachment.name ??
                                                                                "Image"
                                                                            }
                                                                            sx={{
                                                                                width: "100%",
                                                                                height: 160,
                                                                                objectFit:
                                                                                    "cover",
                                                                                borderRadius: 2,
                                                                                cursor:
                                                                                    "pointer",
                                                                            }}
                                                                            onClick={() => {
                                                                                void handleDownloadAttachment(
                                                                                    message,
                                                                                    attachment,
                                                                                );
                                                                            }}
                                                                        />
                                                                    ),
                                                                )}
                                                            </Box>
                                                        )}
                                                        {isStreaming ? (
                                                            showLoadingPlaceholder ? (
                                                                <Typography
                                                                    variant="message"
                                                                    sx={{
                                                                        ...assistantTextSx,
                                                                        color: "text.muted",
                                                                    }}
                                                                >
                                                                    {
                                                                        loadingPhrase ??
                                                                        "Generating your reply"
                                                                    }
                                                                    <Box
                                                                        component="span"
                                                                        sx={{
                                                                            color: "text.muted",
                                                                        }}
                                                                    >
                                                                        {dots}
                                                                    </Box>
                                                                </Typography>
                                                            ) : (
                                                                <Box
                                                                    sx={
                                                                        assistantMarkdownSx
                                                                    }
                                                                >
                                                                    <MarkdownRenderer
                                                                        content={
                                                                            displayText
                                                                        }
                                                                        className="markdown-content"
                                                                    />
                                                                    <Box
                                                                        component="span"
                                                                        sx={cursorSx}
                                                                    >
                                                                        ▍
                                                                    </Box>
                                                                </Box>
                                                            )
                                                        ) : (
                                                            <Box
                                                                sx={
                                                                    assistantMarkdownSx
                                                                }
                                                            >
                                                                <MarkdownRenderer
                                                                    content={
                                                                        displayText
                                                                    }
                                                                    className="markdown-content"
                                                                />
                                                            </Box>
                                                        )}
                                                    </Box>
                                                )}

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

                                                {showAttachments && (
                                                    <Stack
                                                        sx={{
                                                            mt: 1,
                                                            gap: 0.5,
                                                            alignSelf: isSelf
                                                                ? "flex-end"
                                                                : "flex-start",
                                                        }}
                                                    >
                                                        {documentAttachments.map(
                                                            (attachment) => (
                                                                <Box
                                                                    key={
                                                                        attachment.id
                                                                    }
                                                                    sx={{
                                                                        display:
                                                                            "flex",
                                                                        alignItems:
                                                                            "center",
                                                                        gap: 1,
                                                                        px: 1.5,
                                                                        py: 0.75,
                                                                        borderRadius:
                                                                            1.5,
                                                                        bgcolor:
                                                                            "fill.faint",
                                                                    }}
                                                                >
                                                                    <Typography
                                                                        variant="mini"
                                                                        sx={{
                                                                            flex: 1,
                                                                            color: "text.base",
                                                                            overflow:
                                                                                "hidden",
                                                                            textOverflow:
                                                                                "ellipsis",
                                                                            whiteSpace:
                                                                                "nowrap",
                                                                        }}
                                                                    >
                                                                        {
                                                                            attachment.name
                                                                        }
                                                                    </Typography>
                                                                    <Typography
                                                                        variant="mini"
                                                                        sx={{
                                                                            color: "text.muted",
                                                                        }}
                                                                    >
                                                                        {formatBytes(
                                                                            attachment.size,
                                                                        )}
                                                                    </Typography>
                                                                    <IconButton
                                                                        aria-label="Download attachment"
                                                                        sx={
                                                                            actionButtonSx
                                                                        }
                                                                        onClick={() =>
                                                                            void handleDownloadAttachment(
                                                                                message,
                                                                                attachment,
                                                                            )
                                                                        }
                                                                    >
                                                                        <HugeiconsIcon
                                                                            icon={
                                                                                Attachment01Icon
                                                                            }
                                                                            {...smallIconProps}
                                                                        />
                                                                    </IconButton>
                                                                </Box>
                                                            ),
                                                        )}
                                                    </Stack>
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
                                                                    void handleEditMessage(
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
                </Box>

                <Box
                    sx={{
                        px: { xs: 2, md: 4 },
                        position: "absolute",
                        left: 0,
                        right: 0,
                        bottom: 16,
                        zIndex: 5,
                        pointerEvents: "none",
                    }}
                >
                    <Box
                        sx={{ maxWidth: 900, mx: "auto", pointerEvents: "auto" }}
                    >
                        {showModelGate ? (
                            <>
                                {showDownloadProgress &&
                                    downloadStatus?.totalBytes && (
                                        <Box
                                            sx={{
                                                display: "flex",
                                                justifyContent: "flex-end",
                                                mb: 1,
                                                px: 1,
                                            }}
                                        >
                                            <Typography
                                                variant="mini"
                                                sx={{
                                                    color: "text.muted",
                                                    fontVariantNumeric:
                                                        "tabular-nums",
                                                }}
                                            >
                                                {formatBytes(
                                                    downloadStatus.bytesDownloaded ??
                                                        0,
                                                )} / {formatBytes(downloadStatus.totalBytes)}
                                            </Typography>
                                        </Box>
                                    )}
                                <Stack
                                    sx={{
                                        px: 0,
                                        py: 0,
                                        gap: 0.5,
                                        borderRadius: 2,
                                        bgcolor: "background.paper",
                                        border: "1px solid",
                                        borderColor: "divider",
                                        boxShadow:
                                            "0px 12px 32px rgba(0, 0, 0, 0.12)",
                                        position: "relative",
                                        overflow: "hidden",
                                    }}
                                >
                                    {showDownloadProgress && (
                                        <LinearProgress
                                            variant={
                                                downloadStatus?.totalBytes
                                                    ? "determinate"
                                                    : "indeterminate"
                                            }
                                            value={
                                                downloadStatus?.totalBytes
                                                    ? downloadStatus.percent
                                                    : undefined
                                            }
                                            sx={{
                                                position: "absolute",
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                height: 3,
                                                borderRadius:
                                                    "8px 8px 0 0",
                                                pointerEvents: "none",
                                            }}
                                        />
                                    )}
                                    <Stack sx={{ px: 2, py: 2, gap: 1.5 }}>
                                        <Typography variant="h3">
                                            Download to begin using the Chat
                                        </Typography>
                                        <Typography
                                            variant="small"
                                            sx={{ color: "text.muted" }}
                                        >
                                            {downloadStatusLabel ??
                                                (modelGateStatus === "error"
                                                    ? "We couldn't load the model. Try downloading again."
                                                    : downloadSizeLabel)}
                                        </Typography>
                                        {modelGateError && (
                                            <Typography
                                                variant="mini"
                                                sx={{ color: "critical.main" }}
                                            >
                                                {modelGateError}
                                            </Typography>
                                        )}
                                        <Button
                                            variant="contained"
                                            color="accent"
                                            disabled={
                                                modelGateStatus === "downloading" ||
                                                isDownloading
                                            }
                                            onClick={() =>
                                                void handleDownloadModel()
                                            }
                                        >
                                            {modelGateStatus === "downloading" ||
                                            isDownloading
                                                ? "Downloading..."
                                                : "Download"}
                                        </Button>
                                    </Stack>
                                </Stack>
                            </>
                        ) : (
                            <Stack
                                sx={{
                                    px: 0,
                                    py: 0,
                                    gap: 0.5,
                                    borderRadius: 2,
                                    bgcolor: "background.paper",
                                    border: "1px solid",
                                    borderColor: "divider",
                                    boxShadow:
                                        "0px 12px 32px rgba(0, 0, 0, 0.12)",
                                    position: "relative",
                                    overflow: "hidden",
                                }}
                            >
                                {showDownloadProgress && (
                                    <LinearProgress
                                        variant={
                                            downloadStatus?.totalBytes
                                                ? "determinate"
                                                : "indeterminate"
                                        }
                                        value={
                                            downloadStatus?.totalBytes
                                                ? downloadStatus.percent
                                                : undefined
                                        }
                                        sx={{
                                            position: "absolute",
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            height: 3,
                                            borderRadius:
                                                "8px 8px 0 0",
                                            pointerEvents: "none",
                                        }}
                                    />
                                )}
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
                                        <HugeiconsIcon
                                            icon={Edit01Icon}
                                            {...compactIconProps}
                                        />
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
                                            <HugeiconsIcon
                                                icon={Cancel01Icon}
                                                {...smallIconProps}
                                            />
                                        </IconButton>
                                    </Box>
                                )}

                                {pendingDocuments.length > 0 && (
                                    <Box
                                        sx={{
                                            display: "grid",
                                            gridTemplateColumns:
                                                "repeat(2, minmax(0, 1fr))",
                                            gap: 0.5,
                                        }}
                                    >
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
                                                    minWidth: 0,
                                                }}
                                            >
                                                <Typography
                                                    variant="mini"
                                                    sx={{
                                                        flex: 1,
                                                        color: "text.base",
                                                        overflow: "hidden",
                                                        textOverflow: "ellipsis",
                                                        whiteSpace: "nowrap",
                                                    }}
                                                >
                                                    {doc.name}
                                                </Typography>
                                                <Typography
                                                    variant="mini"
                                                    sx={{
                                                        color: "text.muted",
                                                    }}
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
                                    </Box>
                                )}

                                {pendingImages.length > 0 && (
                                    <Box
                                        sx={{
                                            display: "grid",
                                            gridTemplateColumns:
                                                "repeat(2, minmax(0, 1fr))",
                                            gap: 0.5,
                                        }}
                                    >
                                        {pendingImages.map((img) => {
                                            const preview =
                                                pendingImagePreviews[img.id];
                                            return (
                                                <Box
                                                    key={img.id}
                                                    sx={{
                                                        display: "flex",
                                                        alignItems: "center",
                                                        gap: 1,
                                                        px: 1,
                                                        py: 0.75,
                                                        borderRadius: 1.5,
                                                        bgcolor: "fill.faint",
                                                        minWidth: 0,
                                                    }}
                                                >
                                                    {preview && (
                                                        <Box
                                                            component="img"
                                                            src={preview}
                                                            alt={img.name}
                                                            sx={{
                                                                width: 40,
                                                                height: 40,
                                                                borderRadius: 1,
                                                                objectFit:
                                                                    "cover",
                                                            }}
                                                        />
                                                    )}
                                                    <Box
                                                        sx={{
                                                            flex: 1,
                                                            minWidth: 0,
                                                        }}
                                                    >
                                                        <Typography
                                                            variant="mini"
                                                            sx={{
                                                                color: "text.base",
                                                                overflow:
                                                                    "hidden",
                                                                textOverflow:
                                                                    "ellipsis",
                                                                whiteSpace:
                                                                    "nowrap",
                                                            }}
                                                        >
                                                            {img.name}
                                                        </Typography>
                                                        <Typography
                                                            variant="mini"
                                                            sx={{
                                                                color: "text.muted",
                                                            }}
                                                        >
                                                            {formatBytes(
                                                                img.size,
                                                            )}
                                                        </Typography>
                                                    </Box>
                                                    <IconButton
                                                        aria-label="Remove image"
                                                        sx={actionButtonSx}
                                                        onClick={() =>
                                                            removePendingImage(
                                                                img.id,
                                                            )
                                                        }
                                                    >
                                                        <HugeiconsIcon
                                                            icon={Cancel01Icon}
                                                            {...smallIconProps}
                                                        />
                                                    </IconButton>
                                                </Box>
                                            );
                                        })}
                                    </Box>
                                )}

                                <Box
                                    sx={{
                                        display: "flex",
                                        alignItems: "center",
                                        gap: 1,
                                        px: 1,
                                        py: 0.75,
                                        borderRadius: 2,
                                        bgcolor:
                                            "color-mix(in srgb, var(--mui-palette-background-default) 45%, var(--mui-palette-background-paper) 55%)",
                                    }}
                                >
                                    <InputBase
                                        multiline
                                        maxRows={5}
                                        inputRef={inputRef}
                                        placeholder={
                                            isDownloading
                                                ? "Downloading model..."
                                                : "Write a message..."
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
                                            bgcolor: "transparent",
                                            borderRadius: 2,
                                            px: 1.5,
                                            py: 1.5,
                                            minHeight: 48,
                                            display: "flex",
                                            alignItems: "center",
                                            fontFamily: '"Inter", sans-serif',
                                            fontSize: "15px",
                                            lineHeight: 1.7,
                                            color: "text.base",
                                            "& textarea": {
                                                padding: 0,
                                                margin: 0,
                                            },
                                            "& code": {
                                                fontFamily:
                                                    '"JetBrains Mono", monospace',
                                            },
                                        }}
                                    />
                                    {showAttachmentPicker && (
                                        <IconButton
                                            aria-label="Add attachment"
                                            sx={drawerIconButtonSx}
                                            disabled={
                                                isGenerating || isDownloading
                                            }
                                            onClick={openAttachmentMenu}
                                        >
                                            <HugeiconsIcon
                                                icon={Upload01Icon}
                                                {...actionIconProps}
                                            />
                                        </IconButton>
                                    )}
                                    <IconButton
                                        aria-label={
                                            isGenerating
                                                ? "Stop"
                                                : "Send message"
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
                                                pendingDocuments.length === 0 &&
                                                pendingImages.length === 0)
                                        }
                                        sx={{
                                            width: 44,
                                            height: 44,
                                            borderRadius: 2,
                                            bgcolor: "transparent",
                                            color: isGenerating
                                                ? "critical.main"
                                                : "text.muted",
                                            "&:hover": {
                                                bgcolor: "fill.faint",
                                            },
                                            "&.Mui-disabled": {
                                                color: "text.faint",
                                            },
                                        }}
                                    >
                                        {isGenerating ? (
                                            <Box
                                                sx={{
                                                    width: 22,
                                                    height: 22,
                                                    minWidth: 22,
                                                    minHeight: 22,
                                                    borderRadius: "999px",
                                                    bgcolor: "#ffffff",
                                                    display: "inline-flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                }}
                                            >
                                                <Box
                                                    component="svg"
                                                    viewBox="0 0 24 24"
                                                    sx={{
                                                        width: 12,
                                                        height: 12,
                                                        display: "block",
                                                    }}
                                                >
                                                    <path
                                                        d="M4 12C4 8.72077 4 7.08116 4.81382 5.91891C5.1149 5.48891 5.48891 5.1149 5.91891 4.81382C7.08116 4 8.72077 4 12 4C15.2792 4 16.9188 4 18.0811 4.81382C18.5111 5.1149 18.8851 5.48891 19.1862 5.91891C20 7.08116 20 8.72077 20 12C20 15.2792 20 16.9188 19.1862 18.0811C18.8851 18.5111 18.5111 18.8851 18.0811 19.1862C16.9188 20 15.2792 20 12 20C8.72077 20 7.08116 20 5.91891 19.1862C5.48891 18.8851 5.1149 18.5111 4.81382 18.0811C4 16.9188 4 15.2792 4 12Z"
                                                        fill={
                                                            theme.palette.error
                                                                .main
                                                        }
                                                    />
                                                </Box>
                                            </Box>
                                        ) : (
                                            <Box
                                                sx={{
                                                    transform: "rotate(90deg)",
                                                    display: "flex",
                                                }}
                                            >
                                                <HugeiconsIcon
                                                    icon={Navigation06Icon}
                                                    {...actionIconProps}
                                                />
                                            </Box>
                                        )}
                                    </IconButton>
                                </Box>
                            </Stack>
                        )}
                    </Box>
                </Box>
                </Box>
            </Box>

            {showAttachmentPicker && (
                <>
                    <input {...getDocumentInputProps()} />
                    <input {...getImageInputProps()} />
                    <Menu
                        anchorEl={attachmentAnchor}
                        open={Boolean(attachmentAnchor)}
                        onClose={closeAttachmentMenu}
                        anchorOrigin={{ vertical: "top", horizontal: "right" }}
                        transformOrigin={{ vertical: "bottom", horizontal: "right" }}
                    >
                        {showImageAttachment && (
                            <MenuItem
                                onClick={() => handleAttachmentChoice("image")}
                            >
                                Image
                            </MenuItem>
                        )}
                        <MenuItem
                            onClick={() => handleAttachmentChoice("document")}
                        >
                            Document
                        </MenuItem>
                    </Menu>
                </>
            )}

            <Dialog
                open={showSettingsModal}
                onClose={closeSettingsModal}
                fullScreen={isSmall}
                maxWidth="xs"
                fullWidth
            >
                <DialogTitle sx={dialogTitleSx}>Settings</DialogTitle>
                <DialogContent>
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
                                    {savedLocalUser()?.email ?? ""}
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
                                <Typography
                                    variant="small"
                                    sx={{ flex: 1 }}
                                >
                                    Save logs
                                </Typography>
                            </ListItemButton>
                            {isLoggedIn ? (
                                <ListItemButton
                                    onClick={() => {
                                        closeSettingsModal();
                                        handleLogout();
                                    }}
                                    sx={{
                                        ...settingsItemSx,
                                        color: "critical.main",
                                    }}
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
                fullScreen={isSmall}
                maxWidth="xs"
                fullWidth
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

            {DEVELOPER_SETTINGS_ENABLED && (
                <Dialog
                    open={showDeveloperMenu}
                    onClose={closeDeveloperMenu}
                    fullScreen={isSmall}
                    maxWidth="xs"
                    fullWidth
                >
                    <DialogTitle sx={dialogTitleSx}>
                        Developer Settings
                    </DialogTitle>
                    <DialogContent>
                        <Stack sx={{ gap: 1 }}>
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
                                <Typography variant="small" sx={{ flex: 1 }}>
                                    Model settings
                                </Typography>
                                <HugeiconsIcon
                                    icon={ArrowRight01Icon}
                                    {...smallIconProps}
                                />
                            </ListItemButton>
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
            >
                <DialogTitle sx={dialogTitleSx}>Delete chat?</DialogTitle>
                <DialogContent>
                    <Typography variant="body" sx={{ color: "text.muted" }}>
                        Delete {deleteSessionLabel}? This cannot be undone.
                    </Typography>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 3 }}>
                    <Button onClick={handleCancelDeleteSession} color="secondary">
                        Cancel
                    </Button>
                    <Button
                        variant="contained"
                        color="critical"
                        onClick={handleConfirmDeleteSession}
                    >
                        Delete
                    </Button>
                </DialogActions>
            </Dialog>

            <Dialog
                open={showModelSettings}
                onClose={closeModelSettings}
                fullScreen={isSmall}
                maxWidth="sm"
                fullWidth
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
            <Notification
                open={syncNotificationOpen}
                onClose={() => setSyncNotificationOpen(false)}
                attributes={syncNotification}
                horizontal="right"
                vertical="bottom"
                sx={{
                    width: "fit-content",
                    maxWidth: "min(360px, 100vw)",
                    backgroundColor: "transparent",
                    boxShadow: "none",
                    "& .MuiButtonBase-root": {
                        padding: "4px 8px",
                        borderRadius: "999px",
                        minHeight: 0,
                        bgcolor: "background.paper",
                        color: "text.base",
                        boxShadow: "none",
                    },
                    "& .MuiStack-root": {
                        gap: 1,
                    },
                    "& .MuiStack-root svg": {
                        fontSize: "18px",
                    },
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

            {DEVELOPER_SETTINGS_ENABLED && (
                <DevSettings
                    open={showDevSettings}
                    onClose={closeDevSettings}
                />
            )}
        </>
    );
};

export default Page;
