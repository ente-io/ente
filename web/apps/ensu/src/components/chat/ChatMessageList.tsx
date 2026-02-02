import {
    ArrowLeft01Icon,
    ArrowRight01Icon,
    Copy01Icon,
    Edit01Icon,
    RepeatIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import type { SxProps, Theme } from "@mui/material/styles";
import { MarkdownRenderer } from "components/MarkdownRenderer";
import React, { memo, useCallback, useEffect, useMemo, useRef } from "react";
import {
    STREAMING_SELECTION_KEY,
    type BranchSwitcher,
} from "services/chat/branching";
import type { ChatAttachment, ChatMessage } from "services/chat/store";

type DocumentAttachment = {
    id: string;
    name: string;
    text: string;
    size: number;
};

type IconProps = { size: number; strokeWidth: number };

export type ParsedDocuments = { text: string; documents: DocumentAttachment[] };

export interface ChatMessageListProps {
    messages: ChatMessage[];
    attachmentPreviews: Record<string, string>;
    branchSwitchers: Record<string, BranchSwitcher>;
    loadingPhrase: string | null;
    loadingDots: number;
    stickToBottom: boolean;
    onStickToBottomChange: (value: boolean) => void;
    scrollContainerRef: React.MutableRefObject<HTMLDivElement | null>;
    onScroll: () => void;
    onUserScrollIntent: () => void;
    onOpenAttachment: (
        message: ChatMessage,
        attachment: ChatAttachment,
    ) => void;
    onEditMessage: (message: ChatMessage) => void;
    onCopyMessage: (text: string) => void;
    onRetryMessage: (message: ChatMessage) => void;
    onPrevBranch: (switcher: BranchSwitcher) => void;
    onNextBranch: (switcher: BranchSwitcher) => void;
    onRequestPreview: (attachment: ChatAttachment, sessionUuid: string) => void;
    parseDocumentBlocks: (text: string) => ParsedDocuments;
    stripHiddenParts: (text: string) => string;
    formatTime: (timestamp: number) => string;
    isDesktopOverlay: boolean;
    userBubbleBackground: string;
    userMessageTextSx: SxProps<Theme>;
    assistantTextSx: SxProps<Theme>;
    assistantMarkdownSx: SxProps<Theme>;
    streamingMessageSx: SxProps<Theme>;
    actionButtonSx: SxProps<Theme>;
    smallIconProps: IconProps;
    actionIconProps: IconProps;
}

interface ImagePreviewProps {
    attachment: ChatAttachment;
    url?: string;
    height: number;
    scrollContainerRef: React.MutableRefObject<HTMLDivElement | null>;
    onRequestPreview: (attachment: ChatAttachment, sessionUuid: string) => void;
    sessionUuid: string;
    onClick: () => void;
}

const ImagePreview = memo(
    ({
        attachment,
        url,
        height,
        scrollContainerRef,
        onRequestPreview,
        sessionUuid,
        onClick,
    }: ImagePreviewProps) => {
        const placeholderRef = useRef<HTMLDivElement | HTMLImageElement | null>(
            null,
        );
        const requestedRef = useRef(false);

        useEffect(() => {
            if (url || requestedRef.current) return;
            const node = placeholderRef.current;
            if (!node) return;

            if (typeof IntersectionObserver === "undefined") {
                requestedRef.current = true;
                onRequestPreview(attachment, sessionUuid);
                return;
            }

            const observer = new IntersectionObserver(
                (entries) => {
                    if (entries.some((entry) => entry.isIntersecting)) {
                        requestedRef.current = true;
                        onRequestPreview(attachment, sessionUuid);
                        observer.disconnect();
                    }
                },
                {
                    root: scrollContainerRef.current ?? null,
                    rootMargin: "200px",
                },
            );

            observer.observe(node);
            return () => observer.disconnect();
        }, [
            attachment,
            onRequestPreview,
            scrollContainerRef,
            sessionUuid,
            url,
        ]);

        if (url) {
            return (
                <Box
                    ref={placeholderRef}
                    component="img"
                    src={url}
                    alt={attachment.name ?? "Image"}
                    sx={{
                        width: "100%",
                        height,
                        objectFit: "cover",
                        borderRadius: 2,
                        cursor: "pointer",
                    }}
                    onClick={onClick}
                />
            );
        }

        return (
            <Box
                ref={placeholderRef}
                sx={{
                    width: "100%",
                    height,
                    borderRadius: 2,
                    bgcolor: "fill.faint",
                }}
            />
        );
    },
);

interface MessageRowProps {
    message: ChatMessage;
    attachmentPreviews: Record<string, string>;
    branchSwitchers: Record<string, BranchSwitcher>;
    loadingPhrase: string | null;
    loadingDots: number;
    onOpenAttachment: (
        message: ChatMessage,
        attachment: ChatAttachment,
    ) => void;
    onEditMessage: (message: ChatMessage) => void;
    onCopyMessage: (text: string) => void;
    onRetryMessage: (message: ChatMessage) => void;
    onPrevBranch: (switcher: BranchSwitcher) => void;
    onNextBranch: (switcher: BranchSwitcher) => void;
    onRequestPreview: (attachment: ChatAttachment, sessionUuid: string) => void;
    parseDocumentBlocks: (text: string) => ParsedDocuments;
    stripHiddenParts: (text: string) => string;
    formatTime: (timestamp: number) => string;
    scrollContainerRef: React.MutableRefObject<HTMLDivElement | null>;
    userBubbleBackground: string;
    userMessageTextSx: SxProps<Theme>;
    assistantTextSx: SxProps<Theme>;
    assistantMarkdownSx: SxProps<Theme>;
    streamingMessageSx: SxProps<Theme>;
    actionButtonSx: SxProps<Theme>;
    smallIconProps: IconProps;
    actionIconProps: IconProps;
}

const MessageRow = memo(
    ({
        message,
        attachmentPreviews,
        branchSwitchers,
        loadingPhrase,
        loadingDots,
        onOpenAttachment,
        onEditMessage,
        onCopyMessage,
        onRetryMessage,
        onPrevBranch,
        onNextBranch,
        onRequestPreview,
        parseDocumentBlocks,
        stripHiddenParts,
        formatTime,
        scrollContainerRef,
        userBubbleBackground,
        userMessageTextSx,
        assistantTextSx,
        assistantMarkdownSx,
        streamingMessageSx,
        actionButtonSx,
        smallIconProps,
        actionIconProps,
    }: MessageRowProps) => {
        const isSelf = message.sender === "self";
        const isStreaming = message.messageUuid === STREAMING_SELECTION_KEY;
        const switcher = branchSwitchers[message.messageUuid];
        const showSwitcher = !!switcher && switcher.total > 1;
        const timestamp = formatTime(message.createdAt);
        const attachments = message.attachments ?? [];
        const assistantMessagePaddingX = "8px";

        const { displayText, copyText, imageAttachments } = useMemo(() => {
            const imageAttachments = attachments.filter(
                (attachment) => attachment.kind === "image",
            );
            const parsedDocuments = isSelf
                ? parseDocumentBlocks(message.text)
                : { text: message.text, documents: [] };
            const imageCount = imageAttachments.length;
            const fallbackText = imageCount ? "Attached images" : "";
            const displayText = isSelf
                ? parsedDocuments.text || fallbackText
                : message.text || fallbackText;
            const copyText = isSelf
                ? displayText
                : stripHiddenParts(message.text);

            return {
                displayText,
                copyText,
                imageAttachments,
            };
        }, [
            attachments,
            isSelf,
            message.text,
            parseDocumentBlocks,
            stripHiddenParts,
        ]);
        const showLoadingPlaceholder =
            !isSelf && isStreaming && !displayText.trim();
        const dots = ".".repeat(loadingDots);

        return (
            <Box
                sx={{
                    display: "flex",
                    justifyContent: isSelf ? "flex-end" : "flex-start",
                    pl: isSelf ? { xs: 0, lg: 10 } : 0,
                    pr: isSelf ? 0 : { xs: 0, lg: 10 },
                    minWidth: 0,
                    maxWidth: "100%",
                }}
            >
                <Stack
                    sx={{
                        width: { xs: "100%", lg: "85%" },
                        maxWidth: { xs: "100%", lg: 720 },
                        alignItems: isSelf ? "flex-end" : "flex-start",
                        minWidth: 0,
                    }}
                >
                    {isSelf ? (
                        <Box
                            sx={{
                                bgcolor: userBubbleBackground,
                                borderRadius: "18px",
                                px: "12px",
                                py: "12px",
                                alignSelf: "flex-end",
                                maxWidth: "100%",
                                minWidth: 0,
                                overflowWrap: "break-word",
                                wordBreak: "break-word",
                            }}
                        >
                            {imageAttachments.length > 0 && (
                                <Box
                                    sx={{
                                        display: "grid",
                                        gridTemplateColumns:
                                            "repeat(2, minmax(0, 1fr))",
                                        gap: 1,
                                        mb: 1,
                                    }}
                                >
                                    {imageAttachments.map((attachment) => (
                                        <ImagePreview
                                            key={attachment.id}
                                            attachment={attachment}
                                            url={
                                                attachmentPreviews[
                                                    attachment.id
                                                ]
                                            }
                                            height={140}
                                            scrollContainerRef={
                                                scrollContainerRef
                                            }
                                            onRequestPreview={onRequestPreview}
                                            sessionUuid={message.sessionUuid}
                                            onClick={() =>
                                                onOpenAttachment(
                                                    message,
                                                    attachment,
                                                )
                                            }
                                        />
                                    ))}
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
                                px: assistantMessagePaddingX,
                                py: "12px",
                                alignSelf: "flex-start",
                                width: "fit-content",
                                maxWidth: "100%",
                                minWidth: 0,
                                overflowWrap: "break-word",
                                wordBreak: "break-word",
                                ...(isStreaming ? streamingMessageSx : {}),
                            }}
                        >
                            {imageAttachments.length > 0 && (
                                <Box
                                    sx={{
                                        display: "grid",
                                        gridTemplateColumns:
                                            "repeat(2, minmax(0, 1fr))",
                                        gap: 1,
                                        mb: 1,
                                    }}
                                >
                                    {imageAttachments.map((attachment) => (
                                        <ImagePreview
                                            key={attachment.id}
                                            attachment={attachment}
                                            url={
                                                attachmentPreviews[
                                                    attachment.id
                                                ]
                                            }
                                            height={160}
                                            scrollContainerRef={
                                                scrollContainerRef
                                            }
                                            onRequestPreview={onRequestPreview}
                                            sessionUuid={message.sessionUuid}
                                            onClick={() =>
                                                onOpenAttachment(
                                                    message,
                                                    attachment,
                                                )
                                            }
                                        />
                                    ))}
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
                                        {loadingPhrase ??
                                            "Generating your reply"}
                                        <Box
                                            component="span"
                                            sx={{ color: "text.muted" }}
                                        >
                                            {dots}
                                        </Box>
                                    </Typography>
                                ) : (
                                    <Box
                                        sx={assistantMarkdownSx}
                                        className="ensu-markdown-streaming"
                                    >
                                        <MarkdownRenderer
                                            content={displayText}
                                            className="markdown-content"
                                        />
                                    </Box>
                                )
                            ) : (
                                <Box sx={assistantMarkdownSx}>
                                    <MarkdownRenderer
                                        content={displayText}
                                        className="markdown-content"
                                    />
                                </Box>
                            )}
                        </Box>
                    )}


                    <Stack
                        direction="row"
                        sx={{
                            mt: 0.25,
                            gap: 0.5,
                            alignSelf: isSelf ? "flex-end" : "flex-start",
                        }}
                    >
                        {isStreaming ? null : isSelf ? (
                            <>
                                <IconButton
                                    aria-label="Edit"
                                    sx={actionButtonSx}
                                    onClick={() => onEditMessage(message)}
                                >
                                    <HugeiconsIcon
                                        icon={Edit01Icon}
                                        {...actionIconProps}
                                    />
                                </IconButton>
                                <IconButton
                                    aria-label="Copy"
                                    sx={actionButtonSx}
                                    onClick={() => onCopyMessage(copyText)}
                                >
                                    <HugeiconsIcon
                                        icon={Copy01Icon}
                                        {...actionIconProps}
                                    />
                                </IconButton>
                            </>
                        ) : (
                            <>
                                <IconButton
                                    aria-label="Copy"
                                    sx={actionButtonSx}
                                    onClick={() => onCopyMessage(copyText)}
                                >
                                    <HugeiconsIcon
                                        icon={Copy01Icon}
                                        {...actionIconProps}
                                    />
                                </IconButton>
                                <IconButton
                                    aria-label="Retry"
                                    sx={actionButtonSx}
                                    onClick={() => onRetryMessage(message)}
                                >
                                    <HugeiconsIcon
                                        icon={RepeatIcon}
                                        {...actionIconProps}
                                    />
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
                            pl: isSelf ? 0 : assistantMessagePaddingX,
                        }}
                    >
                        {isSelf ? (
                            <>
                                <Box sx={{ flex: 1 }} />
                                {showSwitcher && (
                                    <Stack
                                        direction="row"
                                        sx={{ alignItems: "center", gap: 0.25 }}
                                    >
                                        <IconButton
                                            aria-label="Previous branch"
                                            sx={actionButtonSx}
                                            onClick={() =>
                                                switcher &&
                                                onPrevBranch(switcher)
                                            }
                                        >
                                            <HugeiconsIcon
                                                icon={ArrowLeft01Icon}
                                                {...smallIconProps}
                                            />
                                        </IconButton>
                                        <Typography
                                            variant="small"
                                            sx={{
                                                color: "text.muted",
                                                fontVariantNumeric:
                                                    "tabular-nums",
                                                minWidth: 40,
                                                textAlign: "center",
                                            }}
                                        >
                                            {switcher
                                                ? switcher.currentIndex + 1
                                                : 1}
                                            /{switcher ? switcher.total : 1}
                                        </Typography>
                                        <IconButton
                                            aria-label="Next branch"
                                            sx={actionButtonSx}
                                            onClick={() =>
                                                switcher &&
                                                onNextBranch(switcher)
                                            }
                                        >
                                            <HugeiconsIcon
                                                icon={ArrowRight01Icon}
                                                {...smallIconProps}
                                            />
                                        </IconButton>
                                    </Stack>
                                )}
                                <Typography
                                    variant="mini"
                                    sx={{
                                        color: "text.muted",
                                        fontVariantNumeric: "tabular-nums",
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
                                        fontVariantNumeric: "tabular-nums",
                                    }}
                                >
                                    {timestamp}
                                </Typography>
                                {showSwitcher && (
                                    <Stack
                                        direction="row"
                                        sx={{
                                            alignItems: "center",
                                            gap: 0.25,
                                            ml: 0.75,
                                        }}
                                    >
                                        <IconButton
                                            aria-label="Previous branch"
                                            sx={actionButtonSx}
                                            onClick={() =>
                                                switcher &&
                                                onPrevBranch(switcher)
                                            }
                                        >
                                            <HugeiconsIcon
                                                icon={ArrowLeft01Icon}
                                                {...smallIconProps}
                                            />
                                        </IconButton>
                                        <Typography
                                            variant="small"
                                            sx={{
                                                color: "text.muted",
                                                fontVariantNumeric:
                                                    "tabular-nums",
                                                minWidth: 40,
                                                textAlign: "center",
                                            }}
                                        >
                                            {switcher
                                                ? switcher.currentIndex + 1
                                                : 1}
                                            /{switcher ? switcher.total : 1}
                                        </Typography>
                                        <IconButton
                                            aria-label="Next branch"
                                            sx={actionButtonSx}
                                            onClick={() =>
                                                switcher &&
                                                onNextBranch(switcher)
                                            }
                                        >
                                            <HugeiconsIcon
                                                icon={ArrowRight01Icon}
                                                {...smallIconProps}
                                            />
                                        </IconButton>
                                    </Stack>
                                )}
                                <Box sx={{ flex: 1 }} />
                            </>
                        )}
                    </Stack>
                </Stack>
            </Box>
        );
    },
);

export const ChatMessageList = memo(
    ({
        messages,
        attachmentPreviews,
        branchSwitchers,
        loadingPhrase,
        loadingDots,
        onStickToBottomChange,
        scrollContainerRef,
        onScroll,
        onUserScrollIntent,
        onOpenAttachment,
        onEditMessage,
        onCopyMessage,
        onRetryMessage,
        onPrevBranch,
        onNextBranch,
        onRequestPreview,
        parseDocumentBlocks,
        stripHiddenParts,
        formatTime,
        isDesktopOverlay,
        userBubbleBackground,
        userMessageTextSx,
        assistantTextSx,
        assistantMarkdownSx,
        streamingMessageSx,
        actionButtonSx,
        smallIconProps,
        actionIconProps,
    }: ChatMessageListProps) => {
        const paddingTop = isDesktopOverlay ? 10 : 2;
        const paddingBottom = 16;

        const EmptyPlaceholder = useCallback(() => {
            return (
                <Stack
                    sx={{
                        gap: 1,
                        height: "100%",
                        alignItems: "center",
                        justifyContent: "flex-start",
                        textAlign: "center",
                        width: "100%",
                        maxWidth: { xs: "100%", lg: 900 },
                        mx: { xs: 0, lg: "auto" },
                        pt: "150px",
                    }}
                >
                    <Typography variant="h2">Welcome</Typography>
                    <Typography variant="small" sx={{ color: "text.muted" }}>
                        Type a message to start chatting
                    </Typography>
                </Stack>
            );
        }, []);

        const renderMessage = useCallback(
            (_index: number, message: ChatMessage) => {
                const isStreaming =
                    message.messageUuid === STREAMING_SELECTION_KEY;
                return (
                    <MessageRow
                        message={message}
                        attachmentPreviews={attachmentPreviews}
                        branchSwitchers={branchSwitchers}
                        loadingPhrase={isStreaming ? loadingPhrase : null}
                        loadingDots={isStreaming ? loadingDots : 0}
                        onOpenAttachment={onOpenAttachment}
                        onEditMessage={onEditMessage}
                        onCopyMessage={onCopyMessage}
                        onRetryMessage={onRetryMessage}
                        onPrevBranch={onPrevBranch}
                        onNextBranch={onNextBranch}
                        onRequestPreview={onRequestPreview}
                        parseDocumentBlocks={parseDocumentBlocks}
                        stripHiddenParts={stripHiddenParts}
                        formatTime={formatTime}
                        scrollContainerRef={scrollContainerRef}
                        userBubbleBackground={userBubbleBackground}
                        userMessageTextSx={userMessageTextSx}
                        assistantTextSx={assistantTextSx}
                        assistantMarkdownSx={assistantMarkdownSx}
                        streamingMessageSx={streamingMessageSx}
                        actionButtonSx={actionButtonSx}
                        smallIconProps={smallIconProps}
                        actionIconProps={actionIconProps}
                    />
                );
            },
            [
                actionButtonSx,
                actionIconProps,
                assistantMarkdownSx,
                assistantTextSx,
                attachmentPreviews,
                branchSwitchers,
                formatTime,
                loadingDots,
                loadingPhrase,
                onCopyMessage,
                onEditMessage,
                onNextBranch,
                onOpenAttachment,
                onPrevBranch,
                onRequestPreview,
                onRetryMessage,
                parseDocumentBlocks,
                scrollContainerRef,
                smallIconProps,
                streamingMessageSx,
                stripHiddenParts,
                userBubbleBackground,
                userMessageTextSx,
            ],
        );

        return (
            <Box
                ref={(ref) => {
                    scrollContainerRef.current = ref;
                }}
                onScroll={() => {
                    onScroll();
                    const container = scrollContainerRef.current;
                    if (!container) return;
                    const distance =
                        container.scrollHeight -
                        container.scrollTop -
                        container.clientHeight;
                    onStickToBottomChange(distance <= 120);
                }}
                onWheel={() => {
                    onUserScrollIntent();
                }}
                onTouchMove={() => {
                    onUserScrollIntent();
                }}
                sx={{
                    flex: 1,
                    overflowY: "auto",
                    overflowX: "hidden",
                    bgcolor: "background.paper",
                    overscrollBehaviorY: "contain",
                    minWidth: 0,
                    width: "100%",
                    maxWidth: "100vw",
                    boxSizing: "border-box",
                    px: { xs: 2, sm: 2, md: 3, lg: 4 },
                    pt: paddingTop,
                    pb: paddingBottom,
                    scrollPaddingTop: (theme) => theme.spacing(paddingTop),
                    scrollPaddingBottom: (theme) =>
                        theme.spacing(paddingBottom),
                }}
            >
                {messages.length === 0 ? (
                    <EmptyPlaceholder />
                ) : (
                    <Stack
                        sx={{
                            gap: 3,
                            width: "100%",
                            maxWidth: 900,
                            mx: "auto",
                            minWidth: 0,
                            boxSizing: "border-box",
                        }}
                    >
                        {messages.map((message, index) => (
                            <React.Fragment key={message.messageUuid}>
                                {renderMessage(index, message)}
                            </React.Fragment>
                        ))}
                    </Stack>
                )}
            </Box>
        );
    },
);
