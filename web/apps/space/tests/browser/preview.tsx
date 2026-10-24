import { useEffect, useRef } from "react";
import { createRoot } from "react-dom/client";
import { SpaceInlinePostVideo } from "../../src/components/InlinePostVideo";
import { registerFeedPost } from "../../src/components/feed-video-playback";

const video = { url: "/tests/browser/preview.mp4", durationMs: 1000 };
const imageUrl = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="320" height="240"><path fill="#ff00ff" d="M0 0h320v240H0z"/></svg>')}`;

export const Preview = () => {
    const post = useRef<HTMLElement>(null);
    useEffect(() => registerFeedPost(post.current!), []);
    return (
        <article ref={post}>
            {[true, false].map((isActive, index) => (
                <div className="slide" key={index}>
                    <SpaceInlinePostVideo
                        video={video}
                        imageUrl={imageUrl}
                        isActive={isActive}
                        shouldPreload
                        muted
                    />
                </div>
            ))}
        </article>
    );
};

createRoot(document.getElementById("root")!).render(<Preview />);
