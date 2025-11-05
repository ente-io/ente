import { defineConfig } from "vitepress";
import { sidebar } from "./sidebar";

// https://vitepress.dev/reference/site-config
export default defineConfig({
    base: "/help/", // Serve under /help path
    title: "Ente Help",
    description: "Documentation and help for Ente's products",
    head: [
        ["link", { rel: "icon", type: "image/png", href: "/help/favicon.png" }],
    ],
    cleanUrls: true,
    ignoreDeadLinks: "localhostLinks",
    sitemap: {
        hostname: "https://ente.io/help",
    },
    transformPageData(pageData) {
        // Add canonical URL to all pages
        const canonicalUrl = `https://ente.io/help/${pageData.relativePath}`
            .replace(/index\.md$/, "")
            .replace(/\.md$/, "");
        pageData.frontmatter.canonicalUrl = canonicalUrl;
    },
    async transformHead({ pageData }) {
        const head: any[] = [];
        const canonicalUrl = pageData.frontmatter.canonicalUrl || `https://ente.io/help/`;
        const title = pageData.frontmatter.title || pageData.title || "Ente Help";
        const description = pageData.frontmatter.description || "Documentation and help for Ente's products";
        const ogImage = "https://ente.io/help/og-image.png"; // You can customize this per page if needed

        // Canonical URL
        head.push(["link", { rel: "canonical", href: canonicalUrl }]);

        // Open Graph tags
        head.push(["meta", { property: "og:type", content: "website" }]);
        head.push(["meta", { property: "og:title", content: title }]);
        head.push(["meta", { property: "og:description", content: description }]);
        head.push(["meta", { property: "og:url", content: canonicalUrl }]);
        head.push(["meta", { property: "og:image", content: ogImage }]);
        head.push(["meta", { property: "og:site_name", content: "Ente Help" }]);

        // Twitter Card tags
        head.push(["meta", { name: "twitter:card", content: "summary_large_image" }]);
        head.push(["meta", { name: "twitter:site", content: "@enteio" }]);
        head.push(["meta", { name: "twitter:title", content: title }]);
        head.push(["meta", { name: "twitter:description", content: description }]);
        head.push(["meta", { name: "twitter:image", content: ogImage }]);

        // Meta description
        head.push(["meta", { name: "description", content: description }]);

        // Add FAQ Schema markup for FAQ pages
        if (pageData.relativePath.includes("/faq/") && pageData.relativePath !== "photos/faq/index.md") {
            const faqSchema = await generateFAQSchema(pageData);
            if (faqSchema) {
                head.push([
                    "script",
                    { type: "application/ld+json" },
                    JSON.stringify(faqSchema),
                ]);
            }
        }

        // Add BreadcrumbList schema for better navigation
        const breadcrumbSchema = generateBreadcrumbSchema(pageData);
        if (breadcrumbSchema) {
            head.push([
                "script",
                { type: "application/ld+json" },
                JSON.stringify(breadcrumbSchema),
            ]);
        }

        return head;
    },
    themeConfig: {
        // We use the default theme (with some CSS color overrides). This
        // themeConfig block can be used to further customize the default theme.
        //
        // https://vitepress.dev/reference/default-theme-config
        logo: "/logo.png",
        externalLinkIcon: true,
        editLink: {
            pattern:
                "https://github.com/ente-io/ente/edit/main/docs/docs/:path",
        },
        search: {
            provider: "local",
            options: {
                detailedView: true,
            },
        },
        sidebar: sidebar,
        outline: {
            level: [2, 3],
        },
        socialLinks: [
            { icon: "github", link: "https://github.com/ente-io/ente/" },
            { icon: "twitter", link: "https://twitter.com/enteio" },
            { icon: "discord", link: "https://discord.gg/z2YVKkycX3" },
        ],
    },
});

// Generate FAQ Schema for FAQ pages
async function generateFAQSchema(pageData: any) {
    try {
        const { readFile } = await import("fs/promises");
        const { join } = await import("path");

        // Read the actual markdown file
        const filePath = join(process.cwd(), "docs", pageData.relativePath);
        const content = await readFile(filePath, "utf-8");

        const questions: any[] = [];

        // Match headings with IDs (format: ### Question {#id})
        // Updated regex to better match the content structure
        const questionRegex = /###\s+(.+?)\s+\{#[^}]+\}\s*\n+([\s\S]*?)(?=\n###\s|\n##\s|$)/g;
        let match;

        while ((match = questionRegex.exec(content)) !== null) {
            const question = match[1].trim();
            let answer = match[2]
                .trim()
                // Remove markdown formatting
                .replace(/\*\*([^*]+)\*\*/g, "$1") // Bold
                .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1") // Links
                .replace(/`([^`]+)`/g, "$1") // Inline code
                .replace(/^[-*]\s+/gm, "") // List items
                .replace(/\n+/g, " ") // Newlines to spaces
                .replace(/\s+/g, " ") // Multiple spaces to single
                .trim();

            // Limit answer length but try to end at a sentence
            if (answer.length > 500) {
                answer = answer.substring(0, 500);
                const lastPeriod = answer.lastIndexOf(".");
                if (lastPeriod > 300) {
                    answer = answer.substring(0, lastPeriod + 1);
                }
            }

            if (question && answer && answer.length > 20) {
                questions.push({
                    "@type": "Question",
                    "name": question,
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": answer,
                    },
                });
            }
        }

        if (questions.length === 0) {
            return null;
        }

        return {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": questions,
        };
    } catch (error) {
        console.error(`Error generating FAQ schema for ${pageData.relativePath}:`, error);
        return null;
    }
}

// Generate Breadcrumb Schema
function generateBreadcrumbSchema(pageData: any) {
    const path = pageData.relativePath.replace(/\.md$/, "").replace(/\/index$/, "");
    if (!path || path === "index") return null;

    const parts = path.split("/").filter(Boolean);
    const items = [
        {
            "@type": "ListItem",
            "position": 1,
            "name": "Home",
            "item": "https://ente.io/help/",
        },
    ];

    let currentPath = "https://ente.io/help";
    parts.forEach((part, index) => {
        currentPath += `/${part}`;
        items.push({
            "@type": "ListItem",
            "position": index + 2,
            "name": part.charAt(0).toUpperCase() + part.slice(1).replace(/-/g, " "),
            "item": currentPath,
        });
    });

    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": items,
    };
}
