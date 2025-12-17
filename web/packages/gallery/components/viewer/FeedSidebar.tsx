import CloseIcon from "@mui/icons-material/Close";
import {
    Avatar,
    Box,
    CircularProgress,
    Drawer,
    IconButton,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import { useColorScheme } from "@mui/material/styles";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import { getAvatarColor } from "ente-gallery/utils/avatar-colors";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import type { Comment } from "ente-new/photos/services/comment";
import {
    getAlbumFeed,
    getAnonProfiles,
    type UnifiedReaction,
} from "ente-new/photos/services/social";
import React, { useEffect, useMemo, useState } from "react";

// =============================================================================
// Icons
// =============================================================================

const LikedPhotoIcon: React.FC = () => (
    <svg
        width="17"
        height="15"
        viewBox="0 0 17 15"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M6.99906 13.1537C4.84391 11.5421 0.574219 7.85775 0.574219 4.54219C0.574219 2.35074 2.1824 0.574219 4.39366 0.574219C5.5395 0.574219 6.68533 0.956163 8.21311 2.48394C9.74089 0.956163 10.8867 0.574219 12.0326 0.574219C14.2438 0.574219 15.852 2.35074 15.852 4.54219C15.852 7.85775 11.5823 11.5421 9.42716 13.1537C8.70192 13.696 7.7243 13.696 6.99906 13.1537Z"
            fill="#08C225"
            stroke="#08C225"
            strokeWidth="1.14583"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const CommentedPhotoIcon: React.FC = () => (
    <svg
        width="15"
        height="15"
        viewBox="0 0 15 15"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M7.5 14.25C8.83502 14.25 10.1401 13.8541 11.2501 13.1124C12.3601 12.3707 13.2253 11.3165 13.7362 10.0831C14.2471 8.84971 14.3808 7.49252 14.1203 6.18314C13.8598 4.87377 13.217 3.67104 12.273 2.72703C11.329 1.78303 10.1262 1.14015 8.81686 0.879702C7.50749 0.619252 6.15029 0.752925 4.91689 1.26382C3.68349 1.77471 2.62928 2.63987 1.88758 3.7499C1.14588 4.85994 0.75 6.16498 0.75 7.5C0.75 8.616 1.02 9.66825 1.5 10.5953L0.75 14.25L4.40475 13.5C5.33175 13.98 6.38475 14.25 7.5 14.25Z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const RepliedCommentIcon: React.FC = () => (
    <svg
        width="12"
        height="9"
        viewBox="0 0 12 9"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M4.2334 0.0849609C4.39661 0.0849817 4.55308 0.151147 4.66797 0.268555C4.78252 0.386006 4.84664 0.544829 4.84668 0.709961C4.84668 0.875074 4.78246 1.03389 4.66797 1.15137L2.1748 3.70215H7.76855C8.41316 3.70215 9.34837 3.88326 10.1738 4.42969L10.3379 4.54297L10.5029 4.67188C11.3155 5.34145 11.918 6.39843 11.918 7.94531C11.9179 8.11049 11.8539 8.26927 11.7393 8.38672C11.6244 8.50422 11.4679 8.57119 11.3047 8.57129C11.1413 8.57129 10.985 8.5043 10.8701 8.38672C10.7553 8.26923 10.6905 8.11066 10.6904 7.94531C10.6904 6.70123 10.1974 5.98489 9.61914 5.55859C9.00926 5.10915 8.25891 4.95312 7.76855 4.95312H2.17578L4.66504 7.50098C4.72518 7.55831 4.77424 7.62756 4.80762 7.7041C4.84094 7.78063 4.85886 7.86362 4.86035 7.94727C4.8618 8.03105 4.84614 8.11459 4.81543 8.19238C4.78472 8.27017 4.73883 8.34087 4.68066 8.40039C4.62251 8.45986 4.55306 8.50745 4.47656 8.53906C4.40013 8.57058 4.31786 8.58645 4.23535 8.58496C4.1528 8.58343 4.07139 8.5646 3.99609 8.53027C3.9207 8.4959 3.85295 8.44634 3.79688 8.38477V8.38379L0.263672 4.76953C0.148973 4.65203 0.0849609 4.49242 0.0849609 4.32715C0.085085 4.16205 0.149084 4.00313 0.263672 3.88574L3.79883 0.268555C3.91373 0.151128 4.07015 0.0849609 4.2334 0.0849609Z"
            fill="currentColor"
            stroke="currentColor"
            strokeWidth="0.166667"
        />
    </svg>
);

const LikedCommentIcon: React.FC<{ heartStroke?: string }> = ({
    heartStroke = "white",
}) => (
    <svg
        width="22"
        height="21"
        viewBox="0 0 22 21"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M9.16797 16.043C10.5277 16.043 11.8569 15.6398 12.9875 14.8843C14.1181 14.1289 14.9993 13.0552 15.5196 11.7989C16.04 10.5427 16.1761 9.16035 15.9109 7.82673C15.6456 6.49311 14.9908 5.2681 14.0293 4.30661C13.0678 3.34513 11.8428 2.69035 10.5092 2.42507C9.17559 2.1598 7.79326 2.29595 6.53702 2.8163C5.28078 3.33665 4.20705 4.21784 3.45162 5.34843C2.69618 6.47901 2.29297 7.80823 2.29297 9.16797C2.29297 10.3046 2.56797 11.3764 3.05686 12.3205L2.29297 16.043L6.0154 15.2791C6.95957 15.768 8.03207 16.043 9.16797 16.043Z"
            stroke="currentColor"
            strokeWidth="1.52778"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
        <path
            d="M17.3555 10.0986C18.9264 10.0987 20.0537 11.3666 20.0537 12.8887C20.0536 14.0427 19.3203 15.2043 18.4863 16.1631C17.6399 17.1362 16.6287 17.9692 15.9541 18.4736C15.3852 18.899 14.6148 18.899 14.0459 18.4736C13.3713 17.9692 12.3601 17.1362 11.5137 16.1631C10.6797 15.2043 9.94638 14.0427 9.94629 12.8887C9.94629 11.3666 11.0736 10.0986 12.6445 10.0986C13.3933 10.0986 14.1193 10.34 15 11.1455C15.8807 10.34 16.6067 10.0986 17.3555 10.0986Z"
            stroke={heartStroke}
            strokeWidth="0.685221"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
        <path
            d="M14.2513 18.1992C12.9222 17.2053 10.2891 14.9332 10.2891 12.8885C10.2891 11.537 11.2808 10.4414 12.6445 10.4414C13.3511 10.4414 14.0578 10.677 15 11.6191C15.9421 10.677 16.6488 10.4414 17.3554 10.4414C18.7191 10.4414 19.7109 11.537 19.7109 12.8885C19.7109 14.9332 17.0777 17.2053 15.7487 18.1992C15.3014 18.5336 14.6985 18.5336 14.2513 18.1992Z"
            fill="#08C225"
            stroke="#08C225"
            strokeWidth="0.685221"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const LikedReplyIcon: React.FC<{ heartStroke?: string }> = ({
    heartStroke = "white",
}) => (
    <svg
        width="23"
        height="21"
        viewBox="0 0 23 21"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M8.2334 5.74902C8.39661 5.74904 8.55308 5.81521 8.66797 5.93262C8.78252 6.05007 8.84664 6.20889 8.84668 6.37402C8.84668 6.53914 8.78246 6.69796 8.66797 6.81543L6.1748 9.36621H11.7686C12.4132 9.36621 13.3484 9.54733 14.1738 10.0938L14.3379 10.207L14.5029 10.3359C15.3155 11.0055 15.918 12.0625 15.918 13.6094C15.9179 13.7745 15.8539 13.9333 15.7393 14.0508C15.6244 14.1683 15.4679 14.2352 15.3047 14.2354C15.1413 14.2354 14.985 14.1684 14.8701 14.0508C14.7553 13.9333 14.6905 13.7747 14.6904 13.6094C14.6904 12.3653 14.1974 11.649 13.6191 11.2227C13.0093 10.7732 12.2589 10.6172 11.7686 10.6172H6.17578L8.66504 13.165C8.72518 13.2224 8.77424 13.2916 8.80762 13.3682C8.84094 13.4447 8.85886 13.5277 8.86035 13.6113C8.8618 13.6951 8.84614 13.7787 8.81543 13.8564C8.78472 13.9342 8.73883 14.0049 8.68066 14.0645C8.62251 14.1239 8.55306 14.1715 8.47656 14.2031C8.40013 14.2346 8.31786 14.2505 8.23535 14.249C8.1528 14.2475 8.07139 14.2287 7.99609 14.1943C7.9207 14.16 7.85295 14.1104 7.79688 14.0488V14.0479L4.26367 10.4336C4.14897 10.3161 4.08496 10.1565 4.08496 9.99121C4.08509 9.82611 4.14908 9.6672 4.26367 9.5498L7.79883 5.93262C7.91373 5.81519 8.07015 5.74902 8.2334 5.74902Z"
            fill="currentColor"
            stroke="currentColor"
            strokeWidth="0.166667"
        />
        <path
            d="M19.1396 10.7598C20.4555 10.76 21.3992 11.8217 21.3994 13.0967C21.3994 14.0637 20.7857 15.0374 20.0869 15.8408C19.3777 16.6562 18.5301 17.3537 17.9648 17.7764C17.4882 18.1328 16.8429 18.1328 16.3662 17.7764C15.801 17.3537 14.9533 16.6561 14.2441 15.8408C13.5454 15.0374 12.9316 14.0637 12.9316 13.0967C12.9319 11.8216 13.8763 10.7598 15.1924 10.7598C15.8201 10.7598 16.4265 10.9647 17.165 11.6406C17.9039 10.964 18.5117 10.7598 19.1396 10.7598Z"
            stroke={heartStroke}
            strokeWidth="0.57411"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
        <path
            d="M16.5385 17.5467C15.4249 16.714 13.2188 14.8103 13.2188 13.0971C13.2188 11.9648 14.0497 11.0469 15.1923 11.0469C15.7843 11.0469 16.3764 11.2442 17.1658 12.0336C17.9552 11.2442 18.5472 11.0469 19.1393 11.0469C20.2818 11.0469 21.1128 11.9648 21.1128 13.0971C21.1128 14.8103 18.9066 16.714 17.7931 17.5467C17.4183 17.8269 16.9132 17.8269 16.5385 17.5467Z"
            fill="#08C225"
            stroke="#08C225"
            strokeWidth="0.57411"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

// =============================================================================
// Types
// =============================================================================

/**
 * Information about a feed item click for navigation purposes.
 */
export interface FeedItemClickInfo {
    /** The type of feed item. */
    type: FeedItem["type"];
    /** The file ID to navigate to. */
    fileID: number;
    /**
     * The comment ID to highlight (for comment-related items).
     * For `replied_comment`, this is the reply's comment ID.
     * For `liked_comment` and `liked_reply`, this is the target comment ID.
     */
    commentID?: string;
    /** The collection ID where this activity occurred. */
    collectionID: number;
}

export interface FeedSidebarProps extends ModalVisibilityProps {
    /**
     * The collection (album) to show feed for.
     */
    collection: Collection;
    /**
     * The files in the album, used to display thumbnails in feed items.
     */
    files?: EnteFile[];
    /**
     * The current user's ID.
     */
    currentUserID: number;
    /**
     * A map from user IDs to their email addresses for display.
     */
    emailByUserID: Map<number, string>;
    /**
     * Called when a feed item is clicked for navigation.
     */
    onItemClick?: (info: FeedItemClickInfo) => void;
}

/** A user who performed an action in the feed. */
interface FeedUser {
    userID: number;
    anonUserID?: string;
    userName: string;
    /** Email used for avatar color (may differ from userName for display). */
    email: string;
}

/** Base interface for all feed items. */
interface BaseFeedItem {
    /** Unique identifier for this feed item (for React keys). */
    id: string;
    /** Timestamp of the most recent action in this item. */
    timestamp: number;
}

/** Someone liked your photo (grouped by photo). */
interface LikedPhotoFeedItem extends BaseFeedItem {
    type: "liked_photo";
    fileID: number;
    thumbnailURL?: string;
    users: FeedUser[];
}

/** Someone commented on your photo. */
interface CommentedPhotoFeedItem extends BaseFeedItem {
    type: "commented_photo";
    fileID: number;
    /** The ID of the new comment for navigation. */
    actualCommentID: string;
    thumbnailURL?: string;
    user: FeedUser;
}

/** Someone replied to your comment. */
interface RepliedCommentFeedItem extends BaseFeedItem {
    type: "replied_comment";
    /** The parent comment ID. */
    commentID: string;
    /** The ID of the reply for navigation. */
    replyID: string;
    fileID?: number;
    thumbnailURL?: string;
    user: FeedUser;
}

/** Someone liked your comment (grouped by comment). */
interface LikedCommentFeedItem extends BaseFeedItem {
    type: "liked_comment";
    commentID: string;
    fileID?: number;
    thumbnailURL?: string;
    users: FeedUser[];
}

/** Someone liked your reply (grouped by reply). */
interface LikedReplyFeedItem extends BaseFeedItem {
    type: "liked_reply";
    replyID: string;
    fileID?: number;
    thumbnailURL?: string;
    users: FeedUser[];
}

type FeedItem =
    | LikedPhotoFeedItem
    | CommentedPhotoFeedItem
    | RepliedCommentFeedItem
    | LikedCommentFeedItem
    | LikedReplyFeedItem;

/** Thumbnail URL cache for files. */
type ThumbnailCache = Map<number, string>;

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Get the display name for a user.
 * For anonymous users, uses their entered name from userName.
 * Falls back to "Anonymous" only if userName is empty.
 */
const getUserDisplayName = (
    userID: number,
    userName: string,
    anonUserID?: string,
): string => {
    if (userID === -1 || userID === 0 || anonUserID) {
        return userName || "Anonymous";
    }
    return userName;
};

/**
 * Check if a comment is a reply (has a parent).
 */
const isReply = (comment: Comment): boolean => {
    return !!comment.parentCommentID;
};

/**
 * Process feed items from server-filtered data.
 *
 * The server already filters to only return items relevant to the current user:
 * - Comments on files owned by the user (excluding user's own)
 * - Replies to user's comments
 * - Reactions on files owned by the user
 * - Reactions on user's comments
 *
 * This function categorizes and formats them for display.
 */
const processFeedItems = (
    comments: Comment[],
    reactions: UnifiedReaction[],
    _files: EnteFile[],
    thumbnailCache: ThumbnailCache,
    users: Map<number, string>,
    anonUserNames: Map<string, string>,
    currentUserID: number,
): FeedItem[] => {
    const feedItems: FeedItem[] = [];

    // Helper to get username from user map
    const getUserName = (userID: number): string =>
        users.get(userID) ?? "Unknown";

    // Helper to get display name for anonymous users
    const getAnonUserName = (anonUserID: string | undefined): string =>
        anonUserID
            ? (anonUserNames.get(anonUserID) ??
              `Anonymous ${anonUserID.slice(-4)}`)
            : "Anonymous";

    // Helper to get thumbnail URL from cache
    const getThumbnailURL = (fileID: number | undefined): string | undefined =>
        fileID ? thumbnailCache.get(fileID) : undefined;

    // 1. Process comments - categorize as "commented_photo" or "replied_comment"
    for (const c of comments) {
        if (c.isDeleted) continue;

        // For comments, userName from encData might be an email
        const email = users.get(c.userID) ?? c.encData.userName;

        // Only show "Replied to your comment" if the parent comment belongs to
        // the current user. Otherwise show "Commented on your photo".
        const isReplyToCurrentUser =
            isReply(c) && c.parentCommentUserID === currentUserID;

        if (isReplyToCurrentUser) {
            // This is a reply to the current user's comment
            feedItems.push({
                id: `replied_comment_${c.id}`,
                type: "replied_comment",
                commentID: c.parentCommentID!,
                replyID: c.id,
                fileID: c.fileID,
                thumbnailURL: getThumbnailURL(c.fileID),
                timestamp: c.createdAt,
                user: {
                    userID: c.userID,
                    anonUserID: c.anonUserID,
                    userName: c.encData.userName,
                    email,
                },
            });
        } else {
            // This is a comment on the current user's photo (including replies
            // to other people's comments)
            feedItems.push({
                id: `commented_photo_${c.id}`,
                type: "commented_photo",
                fileID: c.fileID!,
                actualCommentID: c.id,
                thumbnailURL: getThumbnailURL(c.fileID),
                timestamp: c.createdAt,
                user: {
                    userID: c.userID,
                    anonUserID: c.anonUserID,
                    userName: c.encData.userName,
                    email,
                },
            });
        }
    }

    // 2. Process reactions - categorize as "liked_photo", "liked_comment", or "liked_reply"
    // Group photo likes by fileID
    const photoLikes = new Map<
        number,
        { users: FeedUser[]; latestTimestamp: number }
    >();
    // Group comment likes by commentID (server provides fileID from the comment)
    const commentLikes = new Map<
        string,
        {
            users: FeedUser[];
            latestTimestamp: number;
            fileID?: number;
            isReply?: boolean;
        }
    >();

    for (const r of reactions) {
        if (r.isDeleted) continue;

        // For anonymous users, look up name from anonUserNames map
        const isAnonymous = !!r.anonUserID;
        const userName = isAnonymous
            ? getAnonUserName(r.anonUserID)
            : getUserName(r.userID);
        // Use anonUserID for avatar color (consistent with LikesSidebar)
        const email = isAnonymous
            ? (r.anonUserID ?? "anonymous")
            : getUserName(r.userID);
        const user: FeedUser = {
            userID: r.userID,
            anonUserID: r.anonUserID,
            userName,
            email,
        };

        if (r.fileID && !r.commentID) {
            // Reaction on a photo
            const fileID = r.fileID;
            const existing = photoLikes.get(fileID);
            if (existing) {
                existing.users.push(user);
                if (r.createdAt > existing.latestTimestamp) {
                    existing.latestTimestamp = r.createdAt;
                    // Move most recent user to front
                    existing.users.pop();
                    existing.users.unshift(user);
                }
            } else {
                photoLikes.set(fileID, {
                    users: [user],
                    latestTimestamp: r.createdAt,
                });
            }
        } else if (r.commentID) {
            // Reaction on a comment (server populates fileID from the comment)
            const commentID = r.commentID;
            const existing = commentLikes.get(commentID);
            if (existing) {
                existing.users.push(user);
                if (r.createdAt > existing.latestTimestamp) {
                    existing.latestTimestamp = r.createdAt;
                    existing.users.pop();
                    existing.users.unshift(user);
                }
            } else {
                commentLikes.set(commentID, {
                    users: [user],
                    latestTimestamp: r.createdAt,
                    fileID: r.fileID,
                    isReply: r.isCommentReply,
                });
            }
        }
    }

    // Add grouped photo likes to feed
    for (const [fileID, data] of photoLikes) {
        feedItems.push({
            id: `liked_photo_${fileID}`,
            type: "liked_photo",
            fileID,
            thumbnailURL: getThumbnailURL(fileID),
            timestamp: data.latestTimestamp,
            users: data.users,
        });
    }

    // Add grouped comment/reply likes to feed
    for (const [commentID, data] of commentLikes) {
        if (data.isReply) {
            feedItems.push({
                id: `liked_reply_${commentID}`,
                type: "liked_reply",
                replyID: commentID,
                fileID: data.fileID,
                thumbnailURL: getThumbnailURL(data.fileID),
                timestamp: data.latestTimestamp,
                users: data.users,
            });
        } else {
            feedItems.push({
                id: `liked_comment_${commentID}`,
                type: "liked_comment",
                commentID,
                fileID: data.fileID,
                thumbnailURL: getThumbnailURL(data.fileID),
                timestamp: data.latestTimestamp,
                users: data.users,
            });
        }
    }

    // Sort by timestamp (newest first)
    return feedItems.sort((a, b) => b.timestamp - a.timestamp);
};

/**
 * Get the action text for a feed item.
 */
const getActionText = (item: FeedItem): string => {
    switch (item.type) {
        case "liked_photo":
            return "Liked your photo";
        case "commented_photo":
            return "Commented on your photo";
        case "replied_comment":
            return "Replied to your comment";
        case "liked_comment":
            return "Liked your comment";
        case "liked_reply":
            return "Liked your reply";
    }
};

/**
 * Get the users string for display (e.g., "anand@ente.io and 2 others").
 */
const getUsersDisplayText = (users: FeedUser[]): string => {
    if (users.length === 0) return "";
    const firstName = getUserDisplayName(
        users[0]!.userID,
        users[0]!.userName,
        users[0]!.anonUserID,
    );
    if (users.length === 1) {
        return firstName;
    }
    const othersCount = users.length - 1;
    return `${firstName} and ${othersCount} ${othersCount === 1 ? "other" : "others"}`;
};

/**
 * Get the icon component for a feed item type.
 */
const getFeedIcon = (
    type: FeedItem["type"],
    heartStroke: string,
): React.ReactNode => {
    switch (type) {
        case "liked_photo":
            return <LikedPhotoIcon />;
        case "commented_photo":
            return <CommentedPhotoIcon />;
        case "replied_comment":
            return <RepliedCommentIcon />;
        case "liked_comment":
            return <LikedCommentIcon heartStroke={heartStroke} />;
        case "liked_reply":
            return <LikedReplyIcon heartStroke={heartStroke} />;
    }
};

// =============================================================================
// Feed Item Row Component
// =============================================================================

interface FeedItemRowProps {
    item: FeedItem;
    onClick?: () => void;
}

/**
 * A single row in the feed showing an action.
 */
const FeedItemRow: React.FC<FeedItemRowProps> = ({ item, onClick }) => {
    const { mode, systemMode } = useColorScheme();
    const users =
        item.type === "commented_photo" || item.type === "replied_comment"
            ? [item.user]
            : item.users;

    const displayText = getUsersDisplayText(users);
    const actionText = getActionText(item);
    const resolvedMode = mode === "system" ? systemMode : mode;
    const heartStroke = resolvedMode === "dark" ? "#1b1b1b" : "white";

    return (
        <FeedItemContainer onClick={onClick}>
            <IconContainer>{getFeedIcon(item.type, heartStroke)}</IconContainer>
            <FeedItemContent>
                <AvatarStack>
                    {users.slice(0, 3).map((user, index) => {
                        const displayName = getUserDisplayName(
                            user.userID,
                            user.userName,
                            user.anonUserID,
                        );
                        return (
                            <StyledAvatar
                                key={`${user.userID}-${user.anonUserID ?? index}`}
                                sx={{
                                    zIndex: users.length - index,
                                    bgcolor: getAvatarColor(user.email),
                                    color: "#fff",
                                }}
                            >
                                {displayName[0]?.toUpperCase() ?? "A"}
                            </StyledAvatar>
                        );
                    })}
                </AvatarStack>
                <UserNameText>{displayText}</UserNameText>
                <ActionText>{actionText}</ActionText>
            </FeedItemContent>
            {item.thumbnailURL && (
                <ThumbnailImage src={item.thumbnailURL} alt="" />
            )}
        </FeedItemContainer>
    );
};

// =============================================================================
// Main Component
// =============================================================================

/**
 * A sidebar panel for displaying the feed for an album.
 */
/**
 * Extracts navigation info from a feed item for click handling.
 */
const getFeedItemClickInfo = (
    item: FeedItem,
    collectionID: number,
): FeedItemClickInfo => {
    const base = { type: item.type, collectionID };

    switch (item.type) {
        case "liked_photo":
            return { ...base, fileID: item.fileID };
        case "commented_photo":
            return {
                ...base,
                fileID: item.fileID,
                commentID: item.actualCommentID,
            };
        case "replied_comment":
            return { ...base, fileID: item.fileID!, commentID: item.replyID };
        case "liked_comment":
            return { ...base, fileID: item.fileID!, commentID: item.commentID };
        case "liked_reply":
            return { ...base, fileID: item.fileID!, commentID: item.replyID };
    }
};

export const FeedSidebar: React.FC<FeedSidebarProps> = ({
    open,
    onClose,
    collection,
    files = [],
    currentUserID,
    emailByUserID,
    onItemClick,
}) => {
    const [thumbnailCache, setThumbnailCache] = useState<ThumbnailCache>(
        new Map(),
    );
    const [comments, setComments] = useState<Comment[]>([]);
    const [reactions, setReactions] = useState<UnifiedReaction[]>([]);
    const [anonUserNames, setAnonUserNames] = useState<Map<string, string>>(
        new Map(),
    );
    const [isLoading, setIsLoading] = useState(false);

    // Load thumbnails for files that have reactions/comments
    useEffect(() => {
        const loadThumbnails = async () => {
            // Get unique file IDs from comments and reactions
            const fileIDsWithActivity = new Set<number>();
            for (const c of comments) {
                if (c.fileID) fileIDsWithActivity.add(c.fileID);
            }
            for (const r of reactions) {
                if (r.fileID) fileIDsWithActivity.add(r.fileID);
            }

            // Find matching files
            const filesToLoad = files.filter((f) =>
                fileIDsWithActivity.has(f.id),
            );

            const newCache = new Map<number, string>();
            for (const file of filesToLoad) {
                try {
                    const url =
                        await downloadManager.renderableThumbnailURL(file);
                    if (url) {
                        newCache.set(file.id, url);
                    }
                } catch {
                    // Ignore thumbnail loading errors
                }
            }
            setThumbnailCache(newCache);
        };

        if (open && (comments.length > 0 || reactions.length > 0)) {
            void loadThumbnails();
        }
    }, [open, comments, reactions, files]);

    // Fetch social data when sidebar opens
    useEffect(() => {
        const fetchSocialData = async () => {
            if (!open || !collection) return;

            setIsLoading(true);
            try {
                const hasPublicLink = (collection.publicURLs?.length ?? 0) > 0;
                const [feedData, anonProfiles] = await Promise.all([
                    getAlbumFeed(collection.id, collection.key),
                    // Only fetch anon profiles if collection has public links
                    hasPublicLink
                        ? getAnonProfiles(collection.id, collection.key)
                        : Promise.resolve(new Map<string, string>()),
                ]);
                setComments(feedData.comments);
                setReactions(feedData.reactions);
                setAnonUserNames(anonProfiles);
            } catch (e) {
                log.error("Failed to fetch album feed", e);
                setComments([]);
                setReactions([]);
                setAnonUserNames(new Map());
            } finally {
                setIsLoading(false);
            }
        };

        void fetchSocialData();
    }, [open, collection]);

    const feedItems = useMemo(
        () =>
            processFeedItems(
                comments,
                reactions,
                files,
                thumbnailCache,
                emailByUserID,
                anonUserNames,
                currentUserID,
            ),
        [
            comments,
            reactions,
            files,
            thumbnailCache,
            emailByUserID,
            anonUserNames,
            currentUserID,
        ],
    );

    return (
        <SidebarDrawer open={open} onClose={onClose} anchor="right">
            <DrawerContentWrapper>
                <Header>
                    <Typography
                        sx={(theme) => ({
                            color: "#000",
                            fontWeight: 600,
                            ...theme.applyStyles("dark", { color: "#fff" }),
                        })}
                    >
                        {collection.name}
                    </Typography>
                    <CloseButton onClick={onClose}>
                        <CloseIcon sx={{ fontSize: 22 }} />
                    </CloseButton>
                </Header>

                <ContentContainer>
                    {isLoading ? (
                        <LoadingContainer>
                            <CircularProgress size={24} />
                        </LoadingContainer>
                    ) : feedItems.length === 0 ? (
                        <EmptyStateText>No activity yet</EmptyStateText>
                    ) : (
                        feedItems.map((item) => (
                            <FeedItemRow
                                key={item.id}
                                item={item}
                                onClick={
                                    onItemClick
                                        ? () => {
                                              onItemClick(
                                                  getFeedItemClickInfo(
                                                      item,
                                                      collection.id,
                                                  ),
                                              );
                                          }
                                        : undefined
                                }
                            />
                        ))
                    )}
                </ContentContainer>
            </DrawerContentWrapper>
        </SidebarDrawer>
    );
};

// =============================================================================
// Styled Components
// =============================================================================

// Drawer & Layout
const SidebarDrawer = styled(Drawer)(({ theme }) => ({
    "& .MuiDrawer-paper": {
        width: "23vw",
        minWidth: "520px",
        maxWidth: "calc(100% - 32px)",
        height: "calc(100% - 32px)",
        margin: "16px",
        borderRadius: "36px",
        backgroundColor: "#FAFAFA",
        padding: "24px 24px 32px 24px",
        boxShadow: "none",
        border: "1px solid #E0E0E0",
        display: "flex",
        flexDirection: "column",
        overflow: "visible",
        "@media (max-width: 450px)": {
            width: "100%",
            minWidth: "unset",
            maxWidth: "100%",
            height: "100%",
            margin: 0,
            borderRadius: 0,
        },
        ...theme.applyStyles("dark", {
            backgroundColor: "#1b1b1b",
            border: "1px solid rgba(255, 255, 255, 0.18)",
        }),
    },
    "& .MuiBackdrop-root": { backgroundColor: "rgba(0, 0, 0, 0.65)" },
}));

const DrawerContentWrapper = styled(Box)(() => ({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    flex: 1,
    minHeight: 0,
}));

const Header = styled(Stack)(() => ({
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 48,
}));

const CloseButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: "#F5F5F7",
    color: "#000",
    padding: "8px",
    "&:hover": { backgroundColor: "#E5E5E7" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255, 255, 255, 0.12)",
        color: "#fff",
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.16)" },
    }),
}));

const ContentContainer = styled(Box)(({ theme }) => ({
    flex: 1,
    overflow: "auto",
    marginRight: -24,
    paddingRight: 24,
    "&::-webkit-scrollbar": { width: "6px" },
    "&::-webkit-scrollbar-track": { background: "transparent" },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.2)",
        borderRadius: "3px",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.2) transparent",
    ...theme.applyStyles("dark", {
        "&::-webkit-scrollbar-thumb": {
            background: "rgba(255, 255, 255, 0.2)",
        },
        scrollbarColor: "rgba(255, 255, 255, 0.2) transparent",
    }),
}));

// Feed Item Components
const FeedItemContainer = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "flex-start",
    gap: 12,
    marginBottom: 40,
    cursor: "pointer",
    position: "relative",
    "&:not(:last-child)::before": {
        content: '""',
        position: "absolute",
        left: 16,
        top: 33,
        bottom: -40,
        width: 2,
        backgroundImage:
            "repeating-linear-gradient(to bottom, #E6E6E6 0px, #E6E6E6 8px, transparent 8px, transparent 16px)",
        borderRadius: 1,
        ...theme.applyStyles("dark", {
            backgroundImage:
                "repeating-linear-gradient(to bottom, rgba(255, 255, 255, 0.18) 0px, rgba(255, 255, 255, 0.18) 8px, transparent 8px, transparent 16px)",
        }),
    },
    "&:last-child": { marginBottom: 0 },
}));

const IconContainer = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: 33,
    height: 33,
    flexShrink: 0,
    backgroundColor: "#fff",
    borderRadius: "50%",
    position: "relative",
    zIndex: 1,
    ...theme.applyStyles("dark", { backgroundColor: "#2a2a2a" }),
}));

const FeedItemContent = styled(Box)(() => ({
    display: "flex",
    flexDirection: "column",
    gap: 4,
    flex: 1,
    minWidth: 0,
}));

const AvatarStack = styled(Box)(() => ({
    display: "flex",
    flexDirection: "row",
    alignItems: "center",
}));

const StyledAvatar = styled(Avatar)(({ theme }) => ({
    width: 32,
    height: 32,
    fontSize: 14,
    fontWeight: 600,
    border: "2px solid #FAFAFA",
    marginLeft: -8,
    "&:first-of-type": { marginLeft: 0 },
    ...theme.applyStyles("dark", { border: "2px solid #1b1b1b" }),
}));

const UserNameText = styled(Typography)(({ theme }) => ({
    fontWeight: 600,
    fontSize: 14,
    color: "#000",
    whiteSpace: "nowrap",
    overflow: "hidden",
    textOverflow: "ellipsis",
    ...theme.applyStyles("dark", { color: "#fff" }),
}));

const ActionText = styled(Typography)(({ theme }) => ({
    fontSize: 13,
    color: "#666",
    whiteSpace: "nowrap",
    overflow: "hidden",
    textOverflow: "ellipsis",
    ...theme.applyStyles("dark", { color: "rgba(255, 255, 255, 0.7)" }),
}));

const ThumbnailImage = styled("img")(() => ({
    width: 76,
    height: 76,
    borderRadius: 8,
    objectFit: "cover",
    flexShrink: 0,
}));

const LoadingContainer = styled(Box)(() => ({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "48px 0",
}));

const EmptyStateText = styled(Typography)(({ theme }) => ({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    height: "100%",
    // Offset for header (marginBottom: 48) + padding diff (32-24=8) = 56, halved
    marginTop: -28,
    color: "#666",
    ...theme.applyStyles("dark", { color: "rgba(255, 255, 255, 0.6)" }),
}));
