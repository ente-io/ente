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
                        text: "Legacy",
                        link: "/photos/features/legacy/",
                    },
                    {
                        text: "Location tags",
                        link: "/photos/features/location-tags",
                    },
                    {
                        text: "Machine learning",
                        link: "/photos/features/machine-learning",
                    },
                    { text: "Map", link: "/photos/features/map" },
                    {
                        text: "Notifications",
                        link: "/photos/features/notifications",
                    },
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
                    { text: "Installation", link: "/photos/faq/installing" },
                    {
                        text: "Export",
                        link: "/photos/faq/export",
                    },
                    {
                        text: "Metadata",
                        link: "/photos/faq/metadata",
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
                    {
                        text: "Face recognition",
                        link: "/photos/faq/face-recognition",
                    },
                    {
                        text: "Video streaming",
                        link: "/photos/faq/video-streaming",
                    },
                    { text: "Desktop", link: "/photos/faq/desktop" },
                    { text: "Misc", link: "/photos/faq/misc" },
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
                        text: "Missing thumbnails",
                        link: "/photos/troubleshooting/thumbnails",
                    },
                    {
                        text: "Large uploads",
                        link: "/photos/troubleshooting/large-uploads",
                    },
                    {
                        text: "Network drives",
                        link: "/photos/troubleshooting/nas",
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
            { text: "Features", link: "/auth/features/" },
            {
                text: "FAQ",
                collapsed: true,
                items: [
                    { text: "General", link: "/auth/faq/" },
                    { text: "Installation", link: "/auth/faq/installing" },
                    {
                        text: "Enteception",
                        link: "/auth/faq/enteception/",
                    },
                    {
                        text: "Privacy disclosure",
                        link: "/auth/faq/privacy-disclosure/",
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
            {
                text: "Troubleshooting",
                collapsed: true,
                items: [
                    {
                        text: "Windows login",
                        link: "/auth/troubleshooting/windows-login",
                    },
                ],
            },
        ],
    },
    {
        text: "Self hosting",
        collapsed: true,
        items: [
            {
                text: "Get Started",
                link: "/self-hosting/",
            },
            {
                text: "Install",
                collapsed: true,
                items: [
                    {
                        text: "Requirements",
                        link: "/self-hosting/install/requirements",
                    },
                    {
                        text: "Quickstart Script (Recommended)",
                        link: "/self-hosting/install/quickstart",
                    },
                    {
                        text: "Docker Compose",
                        link: "/self-hosting/install/from-source",
                    },
                    {
                        text: "Without Docker",
                        link: "/self-hosting/install/standalone-ente",
                    },
                    {
                        text: "Configuration",
                        link: "/self-hosting/install/config",
                    },
                    {
                        text: "Post Installation",
                        link: "/self-hosting/install/post-install",
                    },
                    {
                        text: "Connecting to Custom Server",
                        link: "/self-hosting/install/custom-server/",
                    },
                ],
            },
            {
                text: "Administration",
                collapsed: true,
                items: [
                    {
                        text: "Creating accounts",
                        link: "/self-hosting/administration/creating-accounts",
                    },
                    {
                        text: "Configuring your server",
                        link: "/self-hosting/administration/museum",
                    },
                    {
                        text: "Configuring S3",
                        link: "/self-hosting/guides/configuring-s3",
                    },
                    {
                        text: "Reverse proxy",
                        link: "/self-hosting/administration/reverse-proxy",
                    },
                ],
            },
            {
                text: "Guides",
                collapsed: true,
                items: [
                    { text: "Introduction", link: "/self-hosting/guides/" },
                    {
                        text: "Administering your server",
                        link: "/self-hosting/guides/admin",
                    },
                    {
                        text: "Configuring CLI for your instance",
                        link: "/self-hosting/guides/selfhost-cli",
                    },
                ],
            },
            {
                text: "Troubleshooting",
                collapsed: true,
                items: [
                    {
                        text: "General",
                        link: "/self-hosting/troubleshooting/misc",
                    },
                    {
                        text: "Bucket CORS",
                        link: "/self-hosting/troubleshooting/bucket-cors",
                    },
                    {
                        text: "Uploads",
                        link: "/self-hosting/troubleshooting/uploads",
                    },
                    {
                        text: "Docker / quickstart",
                        link: "/self-hosting/troubleshooting/docker",
                    },
                    {
                        text: "Ente CLI secrets",
                        link: "/self-hosting/troubleshooting/keyring",
                    },
                ],
            },
            {
                text: "Community Guides",
                collapsed: true,
                items: [
                    {
                        text: "Ente via Tailscale",
                        link: "/self-hosting/guides/tailscale",
                    },
                    {
                        text: "Ente with External S3",
                        link: "/self-hosting/guides/external-s3",
                    },
                ],
            },
            {
                text: "FAQ",
                collapsed: true,
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
                    {
                        text: "Backups",
                        link: "/self-hosting/faq/backup",
                    },
                ],
            },
        ],
    },
];
