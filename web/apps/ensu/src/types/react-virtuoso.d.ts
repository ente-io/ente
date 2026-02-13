declare module "react-virtuoso" {
    import * as React from "react";

    export interface VirtuosoProps<T = unknown> {
        data?: T[];
        itemContent?: (index: number, item: T) => React.ReactNode;
        computeItemKey?: (index: number, item: T) => React.Key;
        components?: Record<string, React.ComponentType<any>>;
        scrollerRef?: React.Ref<HTMLDivElement>;
        followOutput?: boolean | "smooth";
        atBottomStateChange?: (atBottom: boolean) => void;
        style?: React.CSSProperties;
    }

    export const Virtuoso: React.ComponentType<VirtuosoProps<any>>;
}
