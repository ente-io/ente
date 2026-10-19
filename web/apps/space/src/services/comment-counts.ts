const counts = new Map<string, number>();
const listeners = new Set<() => void>();

export const cachedCommentCount = (viewer?: string, postId?: number) =>
    counts.get(`${viewer}:${postId}`);

export const subscribeToCommentCounts = (listener: () => void) => {
    listeners.add(listener);
    return () => {
        listeners.delete(listener);
    };
};

export const rememberCommentCount = (
    viewer: string,
    postId: number,
    count: number,
) => {
    const key = `${viewer}:${postId}`;
    if (counts.get(key) == count) return;
    counts.set(key, count);
    listeners.forEach((listener) => listener());
};

export const clearCommentCounts = () => {
    counts.clear();
    listeners.forEach((listener) => listener());
};
