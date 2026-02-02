import {
    ArrowLeft01Icon,
    ArrowRight01Icon,
    Attachment01Icon,
    Copy01Icon,
    Edit01Icon,
    RepeatIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import type { SxProps, Theme } from "@mui/material/styles";
import { MarkdownRenderer } from "components/MarkdownRenderer";
import React, { memo, useCallback, useEffect, useMemo, useRef } from "react";
import { Virtuoso } from "react-virtuoso";
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
    scrollContainerRef: React.RefObject<HTMLDivElement | null>;
    onScroll: () => void;
    onUserScrollIntent: () => void;
    onOpenAttachment: (
        message: ChatMessage,
        attachment: ChatAttachment,
    ) => void;
    onDownloadAttachment: (
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
    formatBytes: (size: number) => string;
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
    scrollContainerRef: React.RefObject<HTMLDivElement | null>;
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
    onDownloadAttachment: (
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
    formatBytes: (size: number) => string;
    scrollContainerRef: React.RefObject<HTMLDivElement | null>;
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
        onDownloadAttachment,
        onEditMessage,
        onCopyMessage,
        onRetryMessage,
        onPrevBranch,
        onNextBranch,
        onRequestPreview,
        parseDocumentBlocks,
        stripHiddenParts,
        formatTime,
        formatBytes,
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

        const {
            displayText,
            copyText,
            documentAttachments,
            imageAttachments,
            documentCount,
        } = useMemo(() => {
            const imageAttachments = attachments.filter(
                (attachment) => attachment.kind === "image",
            );
            const documentAttachments = attachments.filter(
                (attachment) => attachment.kind === "document",
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

            return {
                displayText,
                copyText,
                documentAttachments,
                imageAttachments,
                documentCount,
            };
        }, [
            attachments,
            isSelf,
            message.text,
            parseDocumentBlocks,
            stripHiddenParts,
        ]);

        const showAttachments = !isStreaming && documentAttachments.length > 0;
        const showLoadingPlaceholder =
            !isSelf && isStreaming && !displayText.trim();
        const dots = ".".repeat(loadingDots);

        return (
            <Box
                sx={{
                    display: "flex",
                    justifyContent: isSelf ? "flex-end" : "flex-start",
                    pl: isSelf ? "80px" : 0,
                    pr: isSelf ? 0 : "80px",
                    minWidth: 0,
                    maxWidth: "100%",
                }}
            >
                <Stack
                    sx={{
                        maxWidth: "min(720px, 85%)",
                        alignItems: isSelf ? "flex-end" : "flex-start",
                        minWidth: 0,
                        width: "100%",
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

                    {isSelf && documentCount > 0 && (
                        <Typography
                            variant="mini"
                            sx={{ mt: 0.5, color: "text.muted" }}
                        >
                            {documentCount} document
                            {documentCount === 1 ? "" : "s"} attached
                        </Typography>
                    )}

                    {showAttachments && (
                        <Stack
                            sx={{
                                mt: 1,
                                gap: 0.5,
                                alignSelf: isSelf ? "flex-end" : "flex-start",
                            }}
                        >
                            {documentAttachments.map((attachment) => (
                                <Box
                                    key={attachment.id}
                                    role="button"
                                    tabIndex={0}
                                    onClick={() =>
                                        onOpenAttachment(message, attachment)
                                    }
                                    onKeyDown={(event) => {
                                        if (
                                            event.key === "Enter" ||
                                            event.key === " "
                                        ) {
                                            event.preventDefault();
                                            onOpenAttachment(
                                                message,
                                                attachment,
                                            );
                                        }
                                    }}
                                    sx={{
                                        display: "flex",
                                        alignItems: "center",
                                        gap: 1,
                                        px: 1.5,
                                        py: 0.75,
                                        borderRadius: 1.5,
                                        bgcolor: "fill.faint",
                                        cursor: "pointer",
                                        transition:
                                            "background-color 120ms ease",
                                        "&:hover": { bgcolor: "fill.light" },
                                        "&:focus-visible": {
                                            outline: "2px solid",
                                            outlineColor: "primary.main",
                                            outlineOffset: 2,
                                        },
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
                                        {attachment.name}
                                    </Typography>
                                    <Typography
                                        variant="mini"
                                        sx={{ color: "text.muted" }}
                                    >
                                        {formatBytes(attachment.size)}
                                    </Typography>
                                    <IconButton
                                        aria-label="Download attachment"
                                        sx={actionButtonSx}
                                        onClick={(event) => {
                                            event.stopPropagation();
                                            onDownloadAttachment(
                                                message,
                                                attachment,
                                            );
                                        }}
                                    >
                                        <HugeiconsIcon
                                            icon={Attachment01Icon}
                                            {...smallIconProps}
                                        />
                                    </IconButton>
                                </Box>
                            ))}
                        </Stack>
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
        stickToBottom,
        onStickToBottomChange,
        scrollContainerRef,
        onScroll,
        onUserScrollIntent,
        onOpenAttachment,
        onDownloadAttachment,
        onEditMessage,
        onCopyMessage,
        onRetryMessage,
        onPrevBranch,
        onNextBranch,
        onRequestPreview,
        parseDocumentBlocks,
        stripHiddenParts,
        formatTime,
        formatBytes,
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
        const Scroller = useMemo(() => {
            return React.forwardRef<
                HTMLDivElement,
                React.HTMLAttributes<HTMLDivElement>
            >(
                (
                    {
                        style,
                        onScroll: onScrollProp,
                        onWheel,
                        onTouchMove,
                        ...rest
                    },
                    ref,
                ) => (
                    <Box
                        ref={ref}
                        {...rest}
                        onScroll={(event) => {
                            onScrollProp?.(event);
                            onScroll();
                        }}
                        onWheel={(event) => {
                            onWheel?.(event);
                            onUserScrollIntent();
                        }}
                        onTouchMove={(event) => {
                            onTouchMove?.(event);
                            onUserScrollIntent();
                        }}
                        style={style}
                        sx={{
                            flex: 1,
                            overflowY: "auto",
                            overflowX: "hidden",
                            px: { xs: 2, md: 4 },
                            pt: isDesktopOverlay ? "calc(64px + 16px)" : 2,
                            pb: 12,
                            bgcolor: "background.paper",
                            overscrollBehaviorY: "contain",
                            minWidth: 0,
                            width: "100%",
                            maxWidth: "100%",
                        }}
                    />
                ),
            );
        }, [isDesktopOverlay, onScroll, onUserScrollIntent]);

        const List = useMemo(() => {
            return React.forwardRef<
                HTMLDivElement,
                React.HTMLAttributes<HTMLDivElement>
            >(({ style, ...rest }, ref) => (
                <Stack
                    ref={ref}
                    {...rest}
                    style={style}
                    sx={{
                        gap: 3,
                        width: "100%",
                        maxWidth: 900,
                        mx: "auto",
                        minWidth: 0,
                    }}
                />
            ));
        }, []);

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
                        maxWidth: 900,
                        mx: "auto",
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
                        onDownloadAttachment={onDownloadAttachment}
                        onEditMessage={onEditMessage}
                        onCopyMessage={onCopyMessage}
                        onRetryMessage={onRetryMessage}
                        onPrevBranch={onPrevBranch}
                        onNextBranch={onNextBranch}
                        onRequestPreview={onRequestPreview}
                        parseDocumentBlocks={parseDocumentBlocks}
                        stripHiddenParts={stripHiddenParts}
                        formatTime={formatTime}
                        formatBytes={formatBytes}
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
                formatBytes,
                formatTime,
                loadingDots,
                loadingPhrase,
                onCopyMessage,
                onDownloadAttachment,
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
            <Virtuoso
                data={messages}
                itemContent={renderMessage}
                scrollerRef={scrollContainerRef}
                followOutput={stickToBottom ? "smooth" : false}
                atBottomStateChange={onStickToBottomChange}
                components={{ Scroller, List, EmptyPlaceholder }}
                computeItemKey={(_index: number, message: ChatMessage) =>
                    message.messageUuid
                }
                style={{ flex: 1, height: "100%" }}
            />
        );
    },
);
