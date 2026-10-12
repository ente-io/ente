import type { SpacePost } from "services/space";
import type { LocalSpaceFeedPost } from "state/app-state";

export type HomeFeedEntry =
    | {
          identity: string;
          item: LocalSpaceFeedPost;
          kind: "local";
          renderKey: string;
      }
    | { identity: string; item: SpacePost; kind: "remote"; renderKey: string };

export const homeFeedSeparatorBefore = (
    entries: HomeFeedEntry[],
    previousNewestPost: Pick<SpacePost, "postId" | "timestampMs"> | undefined,
) => {
    if (!previousNewestPost) return undefined;
    let hasNewPosts = false;
    for (const entry of entries) {
        if (entry.kind != "remote") continue;
        const post = entry.item;
        if (
            post.timestampMs > previousNewestPost.timestampMs ||
            (post.timestampMs == previousNewestPost.timestampMs &&
                post.postId > previousNewestPost.postId)
        ) {
            hasNewPosts = true;
        } else {
            return hasNewPosts ? entry.identity : undefined;
        }
    }
    return undefined;
};

export const homeFeedEntries = (
    feedItems: SpacePost[],
    localFeedPosts: LocalSpaceFeedPost[],
) => {
    const localResolvedPostIds = new Set(
        localFeedPosts.map((item) =>
            item.status == "posted" || item.status == "ready"
                ? item.post.postId
                : item.postId,
        ),
    );
    return [
        ...localFeedPosts.map((item): HomeFeedEntry => ({
            identity:
                item.status == "posted" || item.status == "ready"
                    ? `post:${item.post.postId}`
                    : item.postId
                      ? `post:${item.postId}`
                      : `local:${item.id}`,
            item,
            kind: "local",
            renderKey: `local:${item.id}`,
        })),
        ...feedItems
            .filter((item) => !localResolvedPostIds.has(item.postId))
            .map((item): HomeFeedEntry => ({
                identity: `post:${item.postId}`,
                item,
                kind: "remote",
                renderKey: `post:${item.postId}`,
            })),
    ];
};
