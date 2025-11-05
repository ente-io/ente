// When adding new pages, they need to be manually inserted into their
// appropriate place here.

export const sidebar = [
    {
        text: "Photos",
        items: [
            { text: "Introduction", link: "/photos/" },
            {
                text: "Getting Started",
                collapsed: true,
                items: [
                    { text: "Overview", link: "/photos/getting-started/" },
                    {
                        text: "Installation",
                        link: "/photos/getting-started/installation",
                    },
                    { text: "Sign up", link: "/photos/getting-started/signup" },
                    {
                        text: "Migration",
                        link: "/photos/getting-started/migration",
                    },
                    {
                        text: "Daily use",
                        link: "/photos/getting-started/daily-use",
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
                text: "Features",
                collapsed: true,
                items: [
                    {
                        text: "Account",
                        collapsed: true,
                        items: [
                            {
                                text: "Overview",
                                link: "/photos/features/account/",
                            },
                            {
                                text: "Family plans",
                                link: "/photos/features/account/family-plans",
                            },
                            {
                                text: "Passkeys",
                                link: "/photos/features/account/passkeys",
                            },
                            {
                                text: "Referral program",
                                link: "/photos/features/account/referral-program/",
                            },
                            {
                                text: "Legacy",
                                link: "/photos/features/account/legacy/",
                            },
                        ],
                    },
                    {
                        text: "Backup and Sync",
                        collapsed: true,
                        items: [
                            {
                                text: "Overview",
                                link: "/photos/features/backup-and-sync/",
                            },
                            {
                                text: "Watch folders",
                                link: "/photos/features/backup-and-sync/watch-folders",
                            },
                            {
                                text: "Duplicate detection",
                                link: "/photos/features/backup-and-sync/duplicate-detection",
                            },
                            {
                                text: "Export",
                                link: "/photos/features/backup-and-sync/export",
                            },
                        ],
                    },
                    {
                        text: "Albums and Organization",
                        collapsed: true,
                        items: [
                            {
                                text: "Albums",
                                link: "/photos/features/albums-and-organization/albums",
                            },
                            {
                                text: "Archiving",
                                link: "/photos/features/albums-and-organization/archive",
                            },
                            {
                                text: "Hidden photos",
                                link: "/photos/features/albums-and-organization/hide",
                            },
                            {
                                text: "Deleting photos",
                                link: "/photos/features/albums-and-organization/deleting",
                            },
                            {
                                text: "Uncategorized",
                                link: "/photos/features/albums-and-organization/uncategorized",
                            },
                            {
                                text: "Storage optimization",
                                link: "/photos/features/albums-and-organization/storage-optimization",
                            },
                        ],
                    },
                    {
                        text: "Sharing and Collaboration",
                        collapsed: true,
                        items: [
                            {
                                text: "Sharing",
                                link: "/photos/features/sharing-and-collaboration/share",
                            },
                            {
                                text: "Collaboration",
                                link: "/photos/features/sharing-and-collaboration/collaboration",
                            },
                            {
                                text: "Public links",
                                link: "/photos/features/sharing-and-collaboration/public-links",
                            },
                            {
                                text: "Custom domains",
                                link: "/photos/features/sharing-and-collaboration/custom-domains/",
                            },
                            {
                                text: "Embed albums",
                                link: "/photos/features/sharing-and-collaboration/embed",
                            },
                        ],
                    },
                    {
                        text: "Search and Discovery",
                        collapsed: true,
                        items: [
                            {
                                text: "Overview",
                                link: "/photos/features/search-and-discovery/",
                            },
                            {
                                text: "Machine learning",
                                link: "/photos/features/search-and-discovery/machine-learning",
                            },
                            {
                                text: "Magic search",
                                link: "/photos/features/search-and-discovery/magic-search",
                            },
                            {
                                text: "Face recognition",
                                link: "/photos/features/search-and-discovery/face-recognition",
                            },
                            {
                                text: "Map and location",
                                link: "/photos/features/search-and-discovery/map-and-location",
                            },
                        ],
                    },
                    {
                        text: "Utilities",
                        collapsed: true,
                        items: [
                            {
                                text: "Cast",
                                link: "/photos/features/utilities/cast/",
                            },
                            {
                                text: "CLI",
                                link: "/photos/features/utilities/cli",
                            },
                            {
                                text: "Detect Text (OCR)",
                                link: "/photos/features/utilities/detect-text",
                            },
                            {
                                text: "Notifications",
                                link: "/photos/features/utilities/notifications",
                            },
                            {
                                text: "Video streaming",
                                link: "/photos/features/utilities/video-streaming",
                            },
                        ],
                    },
                ],
            },
            {
                text: "FAQ",
                link: "/photos/faq/",
                collapsed: true,
                items: [
                    {
                        text: "Account Creation",
                        link: "/photos/faq/account-creation",
                    },
                    {
                        text: "Advanced Features",
                        link: "/photos/faq/advanced-features",
                    },
                    {
                        text: "Albums and Organization",
                        link: "/photos/faq/albums-and-organization",
                    },
                    {
                        text: "Backup and Sync",
                        link: "/photos/faq/backup-and-sync",
                    },
                    {
                        text: "Metadata and Editing",
                        link: "/photos/faq/metadata-and-editing",
                    },
                    {
                        text: "Search and Discovery",
                        link: "/photos/faq/search-and-discovery",
                    },
                    {
                        text: "Security and Privacy",
                        link: "/photos/faq/security-and-privacy",
                    },
                    {
                        text: "Sharing and Collaboration",
                        link: "/photos/faq/sharing-and-collaboration",
                    },
                    {
                        text: "Storage and Plans",
                        link: "/photos/faq/storage-and-plans",
                    },
                    {
                        text: "Troubleshooting",
                        link: "/photos/faq/troubleshooting",
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
                    { text: "Introduction", link: "/auth/migration/" },
                    {
                        text: "From Authy",
                        link: "/auth/migration/authy/",
                    },
                    {
                        text: "From Steam",
                        link: "/auth/migration/steam/",
                    },
                    {
                        text: "Export",
                        link: "/auth/migration/export",
                    },
                ],
            },
        ],
    },
    {
        text: "Self-hosting",
        collapsed: true,
        items: [
            {
                text: "Quickstart",
                link: "/self-hosting/",
            },
            {
                text: "Installation",
                collapsed: true,
                items: [
                    {
                        text: "Requirements",
                        link: "/self-hosting/installation/requirements",
                    },
                    {
                        text: "Quickstart script (Recommended)",
                        link: "/self-hosting/installation/quickstart",
                    },
                    {
                        text: "Docker Compose",
                        link: "/self-hosting/installation/compose",
                    },
                    {
                        text: "Manual setup (without Docker)",
                        link: "/self-hosting/installation/manual",
                    },
                    {
                        text: "Environment variables and defaults",
                        link: "/self-hosting/installation/env-var",
                    },
                    {
                        text: "Configuration",
                        link: "/self-hosting/installation/config",
                    },
                    {
                        text: "Post-installation steps",
                        link: "/self-hosting/installation/post-install/",
                    },
                    {
                        text: "Upgrade",
                        link: "/self-hosting/installation/upgrade",
                    },
                ],
            },
            {
                text: "Administration",
                collapsed: true,
                items: [
                    {
                        text: "User management",
                        link: "/self-hosting/administration/users",
                    },
                    {
                        text: "Reverse proxy",
                        link: "/self-hosting/administration/reverse-proxy",
                    },
                    {
                        text: "Object storage",
                        link: "/self-hosting/administration/object-storage",
                    },
                    {
                        text: "Ente CLI",
                        link: "/self-hosting/administration/cli",
                    },
                    {
                        text: "Backup",
                        link: "/self-hosting/administration/backup",
                    },
                ],
            },
            {
                text: "Development",
                collapsed: true,
                items: [
                    {
                        text: "Building mobile apps",
                        link: "/self-hosting/development/mobile-build",
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
                        text: "Running Ente using systemd",
                        link: "/self-hosting/guides/systemd",
                    },
                    {
                        text: "Ente on Windows",
                        link: "/self-hosting/guides/windows",
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
                        text: "Docker / quickstart",
                        link: "/self-hosting/troubleshooting/docker",
                    },
                    {
                        text: "Uploads",
                        link: "/self-hosting/troubleshooting/uploads",
                    },
                    {
                        text: "Ente CLI",
                        link: "/self-hosting/troubleshooting/cli",
                    },
                ],
            },
        ],
    },
];
