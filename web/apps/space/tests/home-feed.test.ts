import { expect, test } from "vitest";
import type { SpacePost } from "../src/services/space";
import type { LocalSpaceFeedPost } from "../src/state/app-state";
import {
    homeFeedEntries,
    homeFeedSeparatorBefore,
} from "../src/utils/home-feed";

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

test.each([1, 3])(
    "separates a refresh with %s new posts from the previous feed",
    (count) => {
        const previous = post(2, 200);
        const newPosts = Array.from({ length: count }, (_, index) =>
            post(count + 2 - index, 300 + count - index),
        );
        expect(
            homeFeedSeparatorBefore(
                homeFeedEntries([...newPosts, previous, post(1, 100)], []),
                previous,
            ),
        ).toBe("post:2");
    },
);

test("does not separate initial loads, unchanged refreshes, or older pages", () => {
    const posts = [post(2, 200), post(1, 100)];
    expect(
        homeFeedSeparatorBefore(homeFeedEntries(posts, []), undefined),
    ).toBeUndefined();
    expect(
        homeFeedSeparatorBefore(homeFeedEntries(posts, []), posts[0]),
    ).toBeUndefined();
    expect(
        homeFeedSeparatorBefore(
            homeFeedEntries([...posts, post(0, 50)], []),
            posts[0],
        ),
    ).toBeUndefined();
});

test("keeps the boundary when the previously newest post has been deleted", () => {
    expect(
        homeFeedSeparatorBefore(
            homeFeedEntries([post(3, 300), post(1, 100)], []),
            post(2, 200),
        ),
    ).toBe("post:1");
});

test("waits for older posts when new posts fill the first page", () => {
    const posts = [post(4, 400), post(3, 300)];
    const previous = post(2, 200);
    expect(
        homeFeedSeparatorBefore(homeFeedEntries(posts, []), previous),
    ).toBeUndefined();
    expect(
        homeFeedSeparatorBefore(
            homeFeedEntries([...posts, previous, post(1, 100)], []),
            previous,
        ),
    ).toBe("post:2");
});

test("uses post order to separate posts sharing a timestamp", () => {
    const previous = post(2, 200);
    expect(
        homeFeedSeparatorBefore(
            homeFeedEntries([post(3, 200), previous, post(1, 100)], []),
            previous,
        ),
    ).toBe("post:2");
});

test("a local upload alone does not create a new-post boundary", () => {
    const previous = post(2, 200);
    const local: LocalSpaceFeedPost = {
        id: "upload",
        post: post(4, 400),
        status: "ready",
    };
    expect(
        homeFeedSeparatorBefore(homeFeedEntries([previous], [local]), previous),
    ).toBeUndefined();
    expect(
        homeFeedSeparatorBefore(
            homeFeedEntries([post(3, 300), previous], [local]),
            previous,
        ),
    ).toBe("post:2");
});
