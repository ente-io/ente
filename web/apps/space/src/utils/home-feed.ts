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
