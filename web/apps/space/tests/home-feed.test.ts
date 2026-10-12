import { expect, test } from "vitest";
import type { SpacePost } from "../src/services/space";
import type { LocalSpaceFeedPost } from "../src/state/app-state";
import { homeFeedEntries } from "../src/utils/home-feed";

const post = (postId: number, timestampMs: number): SpacePost => ({
    friendID: "friend",
    name: "Friend",
    postId,
    spaceId: "friend",
    timestampMs,
    viewerLiked: false,
});

test("existing posts and later pages remain in one continuous feed", () => {
    const posts = [post(3, 300), post(2, 200), post(1, 100)];
    const firstPage = homeFeedEntries(posts.slice(0, 2), []);
    const nextPage = homeFeedEntries(posts, []);
    expect(nextPage.slice(0, 2)).toEqual(firstPage);
    expect(nextPage.map((entry) => entry.item)).toEqual(posts);
    expect(homeFeedEntries(posts, [])).toEqual(nextPage);
});

test.each(["posted", "ready"] as const)(
    "%s uploads are not duplicated when the server returns the post",
    (status) => {
        const uploaded = post(3, 300);
        const existing = post(2, 200);
        const local: LocalSpaceFeedPost = {
            id: "upload",
            post: uploaded,
            status,
        };
        const uploading = homeFeedEntries([existing], [local]);
        const refreshed = homeFeedEntries([uploaded, existing], [local]);
        expect(refreshed).toEqual(uploading);
        expect(refreshed.map((entry) => entry.identity)).toEqual([
            "post:3",
            "post:2",
        ]);
        const resolved = homeFeedEntries([uploaded, existing], []);
        expect(resolved.map((entry) => entry.identity)).toEqual([
            "post:3",
            "post:2",
        ]);
    },
);

test.each(["pending", "failed"] as const)(
    "%s uploads remain before fetched posts and keep their identity when confirmed",
    (status) => {
        const pending = {
            caption: "Uploading",
            frameAspectRatio: 1,
            friendID: "self",
            id: "upload",
            imageUrl: "blob:preview",
            name: "Me",
            photoCount: 1,
            spaceId: "self",
            status,
            timestampMs: 300,
        } satisfies LocalSpaceFeedPost;
        const existing = post(2, 200);
        const entries = homeFeedEntries([existing], [pending]);
        expect(entries.map((entry) => entry.identity)).toEqual([
            "local:upload",
            "post:2",
        ]);
        const confirmed = homeFeedEntries(
            [post(3, 300), existing],
            [{ ...pending, postId: 3 }],
        );
        expect(confirmed.map((entry) => entry.identity)).toEqual([
            "post:3",
            "post:2",
        ]);
        expect(confirmed[0]?.renderKey).toBe(entries[0]?.renderKey);
    },
);

test("own posts stay in the same feed after the local publication is removed", () => {
    const uploaded = { ...post(3, 300), spaceId: "self", friendID: "self" };
    const existing = post(2, 200);
    const local: LocalSpaceFeedPost = {
        id: "upload",
        post: uploaded,
        status: "ready",
    };
    const localEntries = homeFeedEntries([uploaded, existing], [local]);
    const remoteEntries = homeFeedEntries([uploaded, existing], []);
    expect(remoteEntries.map((entry) => entry.identity)).toEqual(
        localEntries.map((entry) => entry.identity),
    );
    expect(remoteEntries.map((entry) => entry.item)).toEqual([
        uploaded,
        existing,
    ]);
});
