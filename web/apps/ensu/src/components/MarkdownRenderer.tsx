import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";

interface MarkdownRendererProps {
    content: string;
    className?: string;
}

export const MarkdownRenderer = ({
    content,
    className,
}: MarkdownRendererProps) => {
    return (
        <ReactMarkdown
            className={className}
            remarkPlugins={[remarkGfm, remarkMath]}
            rehypePlugins={[[rehypeKatex, { strict: false, throwOnError: false, trust: true }]]}
        >
            {content}
        </ReactMarkdown>
    );
};
