// When adding new pages, they need to manually inserted into their appropriate
// place here if you wish them to also appear in the sidebar.

export const sidebar = [
    {
        text: "Photos",
        items: [
            { text: "Introduction", link: "/photos/" },
            {
                text: "Features",
                collapsed: true,
                items: [{ text: "Introduction", link: "/photos/" }],
            },
            {
                text: "FAQ",
                collapsed: true,
                items: [{ text: "Introduction", link: "/photos/" }],
            },
            {
                text: "Troubleshooting",
                collapsed: true,
                items: [{ text: "Introduction", link: "/photos/" }],
            }
        ],
    },
    {
        text: "About",
        link: "/about/",
    },
    {
        text: "Contribute",
        link: "/about/contribute",
    },
];

function sidebarOld() {
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
