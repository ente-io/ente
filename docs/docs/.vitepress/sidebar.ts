// When adding new pages, they need to be manually inserted into their
// appropriate place here.

export const sidebar = [
    {
        text: "Photos",
        items: [
            { text: "Introduction", link: "/photos/" },
            {
                text: "Features",
                collapsed: true,
                items: [
                    { text: "Albums", link: "/photos/features/albums" },
                    { text: "Archiving", link: "/photos/features/archive" },
                    { text: "Cast", link: "/photos/features/cast/" },
                    {
                        text: "Collecting photos",
                        link: "/photos/features/collect",
                    },
                    {
                        text: "Family plans",
                        link: "/photos/features/family-plans",
                    },
                    { text: "Hidden photos", link: "/photos/features/hide" },
                    {
                        text: "Location tags",
                        link: "/photos/features/location-tags",
                    },
                    { text: "Map", link: "/photos/features/map" },
                    {
                        text: "Public link",
                        link: "/photos/features/public-link",
                    },
                    { text: "Quick link", link: "/photos/features/quick-link" },
                    { text: "Referrals", link: "/photos/features/referrals" },
                    { text: "Sharing", link: "/photos/features/sharing" },
                    { text: "Trash", link: "/photos/features/trash" },
                    {
                        text: "Uncategorized",
                        link: "/photos/features/uncategorized",
                    },
                    {
                        text: "Watch folder",
                        link: "/photos/features/watch-folder",
                    },
                ],
            },
            { text: "FAQ", link: "/photos/faq/" },
            {
                text: "Troubleshooting",
                collapsed: true,
                items: [
                    {
                        text: "Files not uploading",
                        link: "/photos/troubleshooting/files-not-uploading",
                    },
                    {
                        text: "Sharing debug logs",
                        link: "/photos/troubleshooting/sharing-logs",
                    },
                ],
            },
        ],
    },
    {
        text: "Auth",
        items: [
            { text: "Introduction", link: "/auth/" },
            {
                text: "Migration guides",
                collapsed: true,
                items: [
                    { text: "Introduction", link: "/auth/migration-guides/" },
                ],
            },
        ],
    },
    {
        text: "Self hosting",
        collapsed: true,
        items: [
            { text: "Getting started", link: "/self-hosting/" },
            {
                text: "Guides",
                items: [
                    { text: "Introduction", link: "/self-hosting/guides/" },
                    {
                        text: "System requirements",
                        link: "/self-hosting/guides/system-requirements",
                    },
                ],
            },
            {
                text: "FAQ",
                items: [
                    {
                        text: "Verification code",
                        link: "/self-hosting/faq/otp",
                    },
                ],
            },
            {
                text: "Troubleshooting",
                items: [
                    {
                        text: "Yarn",
                        link: "/self-hosting/troubleshooting/yarn",
                    },
                ],
            },
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
