import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
    title: "Ente Help",
    description: "Documentation and help for Ente's products",
    head: [["link", { rel: "icon", type: "image/png", href: "/favicon.png" }]],
    cleanUrls: true,
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
        nav: [
            { text: "Photos", link: "/photos/index" },
            { text: "Authenticator", link: "/authenticator/index" },
        ],
        search: {
            provider: "local",
            options: {
                detailedView: true,
            },
        },
        sidebar: {
            "/": sidebarPhotos(),
            "/photos/": sidebarPhotos(),
            "/common/": sidebarPhotos(),
            "/authenticator/": sidebarAuth(),
        },
        socialLinks: [
            { icon: "github", link: "https://github.com/ente-io/ente/" },
            { icon: "twitter", link: "https://twitter.com/enteio" },
            { icon: "discord", link: "https://discord.gg/z2YVKkycX3" },
        ],
    },
});

function sidebarPhotos() {
    return [
        {
            text: "Welcome",
            items: [
                {
                    text: "About",
                    collapsed: true,
                    link: "/about/company",
                    items: [
                        { text: "Company", link: "/about/company" },
                        { text: "Products", link: "/about/products" },
                        { text: "Plans", link: "/about/plans" },
                        { text: "Support", link: "/about/support" },
                        { text: "Community", link: "/about/community" },
                        { text: "Open source", link: "/about/open-source" },
                        { text: "Contribute", link: "/about/contribute" },
                    ],
                },
                {
                    text: "Features",
                    collapsed: true,
                    items: [
                        {
                            text: "Family Plan",
                            link: "/photos/features/family-plan",
                        },
                        { text: "Albums", link: "/photos/features/albums" },
                        { text: "Archive", link: "/photos/features/archive" },
                        { text: "Hidden", link: "/photos/features/hidden" },
                        { text: "Map", link: "/photos/features/map" },
                        {
                            text: "Location Tags",
                            link: "/photos/features/location",
                        },
                        {
                            text: "Collect Photos",
                            link: "/photos/features/collect",
                        },
                        {
                            text: "Public links",
                            link: "/photos/features/public-links",
                        },
                        {
                            text: "Quick link",
                            link: "/photos/features/quick-link",
                        },
                        {
                            text: "Watch folder",
                            link: "/photos/features/watch-folder",
                        },
                        { text: "Trash", link: "/photos/features/trash" },
                        {
                            text: "Uncategorized",
                            link: "/photos/features/uncategorized",
                        },
                        {
                            text: "Referral Plan",
                            link: "/photos/features/referral",
                        },
                        {
                            text: "Live & Motion Photos",
                            link: "/photos/features/live-photos",
                        },
                        { text: "Cast", link: "/photos/features/cast" },
                    ],
                },
                {
                    text: "Troubleshoot",
                    collapsed: true,
                    link: "/photos/troubleshooting/files-not-uploading",
                    items: [
                        {
                            text: "Files not uploading",
                            link: "/photos/troubleshooting/files-not-uploading",
                        },
                        {
                            text: "Failed to play video",
                            link: "/photos/troubleshooting/video-not-playing",
                        },
                        {
                            text: "Report bug",
                            link: "/photos/troubleshooting/report-bug",
                        },
                    ],
                },
            ],
        },
    ];
}

function sidebarAuth() {
    return [
        {
            text: "About",
            collapsed: true,
            link: "/about/company",
            items: [
                { text: "Company", link: "/about/company" },
                { text: "Products", link: "/about/products" },
                { text: "Community", link: "/about/community" },
                { text: "Open source", link: "/about/open-source" },
                { text: "Contribute", link: "/about/contribute" },
            ],
        },
        {
            text: "FAQ",
            link: "/authenticator/faq/faq",
        },
        {
            text: "Contribute",
            link: "/authenticator/support/contribute",
        },
    ];
}
