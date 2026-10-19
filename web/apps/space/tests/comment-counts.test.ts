import { beforeEach, expect, test, vi } from "vitest";
import {
    cachedCommentCount,
    clearCommentCounts,
    subscribeToCommentCounts,
} from "../src/services/comment-counts";
import { patchCachedSpaceFeedPost } from "../src/services/feed-cache";
import { ensureCurrentSpaceContext } from "../src/services/profile";
import {
    loadCurrentComments,
    loadCurrentFeedPage,
    loadCurrentSpaceProfilePostsPage,
} from "../src/services/space";

vi.mock("ente-base/log", () => ({ default: { warn: vi.fn() } }));
vi.mock("ente-base/log-web", () => ({ logToDisk: vi.fn() }));
vi.mock("ente-accounts/services/accounts-db", () => ({
    savedPartialLocalUser: () => ({ id: 1 }),
}));
vi.mock("services/feed-cache", () => ({ patchCachedSpaceFeedPost: vi.fn() }));
vi.mock("services/profile", () => ({
    ensureCurrentSpaceContext: vi.fn(),
    persistCurrentOwnedSpaces: vi.fn(),
    releaseCurrentSpaceContext: vi.fn(),
}));

const context = {
    listComments: vi.fn(),
    listFeed: vi.fn(),
    listPosts: vi.fn(),
};
const actor = {
    spaceId: "friend",
    spaceSlug: "maya",
    profile: { fullName: "Maya Patel" },
};
const post = (commentCount: number) => ({
    postId: 42,
    spaceId: "friend",
    commentCount,
    author: actor,
    createdAt: "2026-10-19T06:00:00Z",
    photos: [{ asset: {} }],
});

beforeEach(() => {
    vi.resetAllMocks();
    clearCommentCounts();
    vi.mocked(ensureCurrentSpaceContext).mockResolvedValue(
        context as unknown as Awaited<
            ReturnType<typeof ensureCurrentSpaceContext>
        >,
    );
});

test("keeps the updated count after the viewer closes and reopens with an old post snapshot", async () => {
    context.listFeed.mockResolvedValue({ items: [post(0)] });
    const feed = await loadCurrentFeedPage("viewer");
    const snapshot = feed.items[0]!;
    const updateViewer = vi.fn();
    const closeViewer = subscribeToCommentCounts(updateViewer);

    context.listComments.mockResolvedValue({
        items: [{ commentId: "comment", deleted: false, reactions: [] }],
    });
    await loadCurrentComments("viewer", "friend", 42);
    expect(updateViewer).toHaveBeenCalledOnce();
    expect(patchCachedSpaceFeedPost).toHaveBeenCalledWith("viewer", 42, {
        commentCount: 1,
    });
    closeViewer();

    expect(snapshot.commentCount).toBe(0);
    expect(cachedCommentCount("viewer", snapshot.postId)).toBe(1);
});

test("counts replies across pages and removes deleted comments from the total", async () => {
    context.listComments
        .mockResolvedValueOnce({
            items: [{ commentId: "parent", deleted: false, reactions: [] }],
            nextCursor: "replies",
        })
        .mockResolvedValueOnce({
            items: [
                {
                    commentId: "reply",
                    parentId: "parent",
                    deleted: false,
                    reactions: [],
                },
                { commentId: "deleted", deleted: true, reactions: [] },
            ],
        });
    await loadCurrentComments("viewer", "friend", 42);
    expect(cachedCommentCount("viewer", 42)).toBe(2);

    context.listComments.mockResolvedValue({
        items: [{ commentId: "parent", deleted: true, reactions: [] }],
    });
    await loadCurrentComments("viewer", "friend", 42);
    expect(cachedCommentCount("viewer", 42)).toBe(0);
});

test("uses fresh feed and profile counts after other people comment or delete", async () => {
    context.listComments.mockResolvedValue({ items: [] });
    await loadCurrentComments("viewer", "friend", 42);

    context.listFeed.mockResolvedValue({ items: [post(3)] });
    await loadCurrentFeedPage("viewer");
    expect(cachedCommentCount("viewer", 42)).toBe(3);

    context.listPosts.mockResolvedValue({ items: [post(1)] });
    await loadCurrentSpaceProfilePostsPage("friend", "viewer");
    expect(cachedCommentCount("viewer", 42)).toBe(1);
});

test("isolates viewers and posts and clears counts on logout", async () => {
    context.listFeed.mockResolvedValue({ items: [post(2)] });
    await loadCurrentFeedPage("viewer");
    expect(cachedCommentCount("other-viewer", 42)).toBeUndefined();
    expect(cachedCommentCount("viewer", 43)).toBeUndefined();

    clearCommentCounts();
    expect(cachedCommentCount("viewer", 42)).toBeUndefined();
});
