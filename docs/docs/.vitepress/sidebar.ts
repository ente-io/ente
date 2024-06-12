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
                    {
                        text: "Background sync",
                        link: "/photos/features/background",
                    },
                    { text: "Backup", link: "/photos/features/backup" },
                    { text: "Cast", link: "/photos/features/cast/" },
                    {
                        text: "Collaboration",
                        link: "/photos/features/collaborate",
                    },
                    {
                        text: "Collecting photos",
                        link: "/photos/features/collect",
                    },
                    {
                        text: "Deduplicate",
                        link: "/photos/features/deduplicate",
                    },
                    {
                        text: "Family plans",
                        link: "/photos/features/family-plans",
                    },
                    {
                        text: "Free up space",
                        link: "/photos/features/free-up-space/",
                    },
                    { text: "Hidden photos", link: "/photos/features/hide" },
                    {
                        text: "Location tags",
                        link: "/photos/features/location-tags",
                    },
                    { text: "Map", link: "/photos/features/map" },
                    {
                        text: "Passkeys",
                        link: "/photos/features/passkeys",
                    },
                    {
                        text: "Public link",
                        link: "/photos/features/public-link",
                    },
                    { text: "Quick link", link: "/photos/features/quick-link" },
                    {
                        text: "Referral program",
                        link: "/photos/features/referral-program/",
                    },
                    { text: "Sharing", link: "/photos/features/share" },
                    { text: "Trash", link: "/photos/features/trash" },
                    {
                        text: "Uncategorized",
                        link: "/photos/features/uncategorized",
                    },
                    {
                        text: "Watch folders",
                        link: "/photos/features/watch-folders",
                    },
                ],
            },
            {
                text: "Migration",
                collapsed: true,
                items: [
                    {
                        text: "Introduction",
                        link: "/photos/migration/",
                    },

                    {
                        text: "From Google Photos",
                        link: "/photos/migration/from-google-photos/",
                    },
                    {
                        text: "From Apple Photos",
                        link: "/photos/migration/from-apple-photos/",
                    },
                    {
                        text: "From Amazon Photos",
                        link: "/photos/migration/from-amazon-photos",
                    },
                    {
                        text: "From your hard disk",
                        link: "/photos/migration/from-local-hard-disk",
                    },
                    {
                        text: "Exporting your data",
                        link: "/photos/migration/export/",
                    },
                ],
            },
            {
                text: "FAQ",
                collapsed: true,
                items: [
                    { text: "General", link: "/photos/faq/general" },
                    {
                        text: "Export",
                        link: "/photos/faq/export",
                    },
                    {
                        text: "Security and privacy",
                        link: "/photos/faq/security-and-privacy",
                    },
                    {
                        text: "Subscription and plans",
                        link: "/photos/faq/subscription",
                    },
                    {
                        text: "Hide vs archive",
                        link: "/photos/faq/hidden-and-archive",
                    },
                ],
            },
            {
                text: "Troubleshooting",
                collapsed: true,
                items: [
                    {
                        text: "Desktop install",
                        link: "/photos/troubleshooting/desktop-install/",
                    },
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
                text: "FAQ",
                collapsed: true,
                items: [
                    { text: "General", link: "/auth/faq/" },
                    {
                        text: "Enteception",
                        link: "/auth/faq/enteception/",
                    },
                ],
            },
            {
                text: "Migration",
                collapsed: true,
                items: [
                    { text: "Introduction", link: "/auth/migration-guides/" },
                    {
                        text: "From Authy",
                        link: "/auth/migration-guides/authy/",
                    },
                    {
                        text: "From Steam",
                        link: "/auth/migration-guides/steam/",
                    },
                    {
                        text: "From others",
                        link: "/auth/migration-guides/import",
                    },
                    {
                        text: "Exporting your data",
                        link: "/auth/migration-guides/export",
                    },
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
                        text: "Connect to custom server",
                        link: "/self-hosting/guides/custom-server/",
                    },
                    {
                        text: "Hosting the web app",
                        link: "/self-hosting/guides/web-app",
                    },
                    {
                        text: "Administering your server",
                        link: "/self-hosting/guides/admin",
                    },

                    {
                        text: "Mobile build",
                        link: "/self-hosting/guides/mobile-build",
                    },
                    {
                        text: "System requirements",
                        link: "/self-hosting/guides/system-requirements",
                    },
                    {
                        text: "Configuring S3",
                        link: "/self-hosting/guides/configuring-s3",
                    },
                    {
                        text: "Using external S3",
                        link: "/self-hosting/guides/external-s3",
                    },
                ],
            },
            {
                text: "FAQ",
                items: [
                    { text: "General", link: "/self-hosting/faq/" },
                    {
                        text: "Verification code",
                        link: "/self-hosting/faq/otp",
                    },
                    {
                        text: "Shared albums",
                        link: "/self-hosting/faq/sharing",
                    },
                ],
            },
            {
                text: "Troubleshooting",
                items: [
                    {
                        text: "Uploads",
                        link: "/self-hosting/troubleshooting/uploads",
                    },
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
