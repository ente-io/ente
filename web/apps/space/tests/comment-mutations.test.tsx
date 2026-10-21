import React, { type EffectCallback, type SetStateAction } from "react";
import { beforeEach, expect, test, vi } from "vitest";
import { PostComments } from "../src/components/PostComments";
import type { SpaceComment } from "../src/services/space";

const mocks = vi.hoisted(() => ({
    hooks: [] as unknown[],
    index: 0,
    effects: [] as EffectCallback[],
    load: vi.fn(),
    react: vi.fn(),
    delete: vi.fn(),
    create: vi.fn(),
}));

vi.mock("react", async (importOriginal) => {
    const actual = await importOriginal<typeof import("react")>();
    const useState = <T,>(initial?: T | (() => T)) => {
        const index = mocks.index++;
        if (!(index in mocks.hooks))
            mocks.hooks[index] =
                typeof initial == "function" ? (initial as () => T)() : initial;
        return [
            mocks.hooks[index] as T,
            (value: SetStateAction<T>) => {
                mocks.hooks[index] =
                    typeof value == "function"
                        ? (value as (previous: T) => T)(mocks.hooks[index] as T)
                        : value;
            },
        ] as const;
    };
    return {
        ...actual,
        default: {
            ...actual,
            useState,
            useRef: <T,>(value: T) => useState({ current: value })[0],
            useCallback: <T,>(callback: T) => callback,
            useMemo: <T,>(callback: () => T) => callback(),
            useEffect: (effect: EffectCallback) => mocks.effects.push(effect),
            useLayoutEffect: vi.fn(),
        },
    };
});
vi.mock("@mui/material", () => ({
    Box: "box",
    CircularProgress: "progress",
    ClickAwayListener: "click-away",
    Dialog: "dialog",
    Grow: "grow",
    Popper: "popper",
    Slide: "slide",
    useMediaQuery: () => false,
}));
vi.mock("components/AvatarImage", () => ({ SpaceAvatarImage: "avatar" }));
vi.mock("components/BottomSheetTransition", () => ({
    SpaceBottomSheetTransition: "transition",
}));
vi.mock("components/CommentComposer", () => ({
    SpaceCommentComposer: "composer",
}));
vi.mock("components/MessageActionMenu", () => ({
    CopyIcon: "copy",
    DeleteIcon: "delete",
    ReplyIcon: "reply",
    MessageActionMenuItem: "menu-item",
    MessageActionMenuList: "menu",
}));
vi.mock("components/MessageReactionPicker", () => ({
    MessageQuickReactions: "quick-reactions",
    MessageReactionPicker: "picker",
}));
vi.mock("components/ReplyComposerPreview", () => ({
    ReplyComposerPreview: "preview",
}));
vi.mock("data/emojis", () => ({ emojiName: () => "emoji" }));
vi.mock("hooks/use-browser-back-close", () => ({
    useBrowserBackClose: vi.fn(),
}));
vi.mock("hooks/use-pwa-install-prompt", () => ({ isSpaceIOS: () => false }));
vi.mock("styles/colors", () => import("../src/styles/colors"));
vi.mock("utils/route-transitions", () => ({ useSpaceRouter: vi.fn() }));
vi.mock("services/space", () => ({
    loadCurrentComments: mocks.load,
    setCurrentCommentReaction: mocks.react,
    deleteCurrentComment: mocks.delete,
    createCurrentComment: mocks.create,
    loadCurrentFriendAvatarURL: vi.fn(),
    markCurrentNotificationItemsRead: vi.fn(),
    removeCurrentCommentReaction: vi.fn(),
}));

const comment: SpaceComment = {
    commentId: "comment",
    parentId: "",
    replyToId: "",
    text: "Hello",
    createdAt: "2026-10-21T00:00:00Z",
    deleted: false,
    canDelete: true,
    reactions: [],
    unreadNotificationIds: [],
};

type Element = React.ReactElement<Record<string, unknown>>;

const elements = (node: React.ReactNode): Element[] => {
    if (Array.isArray(node)) return node.flatMap(elements);
    if (!React.isValidElement<Record<string, unknown>>(node)) return [];
    const children = node.props.children;
    return [
        node,
        ...elements(
            typeof children == "function"
                ? (children as (props: object) => React.ReactNode)({
                      placement: "bottom-start",
                  })
                : (children as React.ReactNode),
        ),
    ];
};

const render = () => {
    mocks.index = 0;
    return elements(
        PostComments({
            viewer: "viewer",
            owner: "owner",
            postId: 42,
            draft: { text: "New comment" },
            setDraft: vi.fn(),
            onClose: vi.fn(),
        }) as React.ReactNode,
    );
};

const composer = () => render().find((node) => node.type == "composer")!;
const alert = () => render().find((node) => node.props.role == "alert");

const mutate = (kind: "react" | "delete") => {
    const row = render().find((node) => node.props.comment === comment)!;
    if (kind == "react") {
        (row.props.onReact as (emoji: string) => void)("❤️");
    } else {
        (row.props.onOpenActions as (anchor: object, source: string) => void)(
            {},
            "contextmenu",
        );
        const button = render().find((node) => node.props.label == "Delete")!;
        (button.props.onClick as () => void)();
    }
};

beforeEach(async () => {
    vi.resetAllMocks();
    mocks.hooks = [];
    mocks.effects = [];
    mocks.load.mockResolvedValue([comment]);
    render();
    mocks.effects[0]!();
    await vi.waitFor(() => expect(composer().props.sendDisabled).toBe(false));
});

test.each(["react", "delete"] as const)(
    "a failed %s keeps the composer usable when the discussion refresh succeeds",
    async (kind) => {
        mocks[kind].mockRejectedValueOnce(new Error("Request failed"));
        mutate(kind);
        await vi.waitFor(() => expect(alert()).toBeDefined());
        expect(mocks.load).toHaveBeenCalledTimes(2);
        expect(composer().props.disabled).toBeFalsy();
        await (composer().props.onSend as (text: string) => Promise<void>)(
            "Still able to comment",
        );
        expect(mocks.create).toHaveBeenCalledWith(
            "viewer",
            "owner",
            42,
            expect.any(String),
            undefined,
            "Still able to comment",
        );
        mocks[kind].mockResolvedValueOnce(undefined);
        mutate(kind);
        await vi.waitFor(() => expect(mocks.load).toHaveBeenCalledTimes(3));
        expect(alert()).toBeUndefined();
        expect(composer().props.disabled).toBeFalsy();
    },
);

test("a failed refresh still disables the unavailable discussion after a mutation fails", async () => {
    mocks.react.mockRejectedValueOnce(new Error("Request failed"));
    mocks.load.mockRejectedValueOnce(new Error("Access denied"));
    mutate("react");
    await vi.waitFor(() => expect(alert()).toBeDefined());
    expect(composer().props.disabled).toBe(true);
    expect(alert()!.props.children).toContain(
        "Discussion unavailable. Access may have changed or the post may have been deleted.",
    );
});
