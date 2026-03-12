import AlternateEmailIcon from "@mui/icons-material/AlternateEmail";
import ForumOutlinedIcon from "@mui/icons-material/ForumOutlined";
import GitHubIcon from "@mui/icons-material/GitHub";
import RedditIcon from "@mui/icons-material/Reddit";
import XIcon from "@mui/icons-material/X";
import YouTubeIcon from "@mui/icons-material/YouTube";
import { IconButton, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";

const openExternal = (url: string) => window.open(url, "_blank", "noopener");

const socialLinks = [
    {
        icon: ForumOutlinedIcon,
        label: "Discord",
        url: "https://ente.io/discord",
    },
    {
        icon: YouTubeIcon,
        label: "YouTube",
        url: "https://www.youtube.com/@entestudio",
    },
    { icon: GitHubIcon, label: "GitHub", url: "https://github.com/ente-io" },
    { icon: XIcon, label: "X", url: "https://twitter.com/enteio" },
    {
        icon: AlternateEmailIcon,
        label: "Mastodon",
        url: "https://fosstodon.org/@ente",
    },
    { icon: RedditIcon, label: "Reddit", url: "https://reddit.com/r/enteio" },
] as const;

const buildLabel = () => {
    const sha = process.env.gitSHA;
    return sha ? `${t("build")} ${sha.slice(0, 7)}` : undefined;
};

export const LockerSocialFooter: React.FC = () => {
    const build = buildLabel();

    return (
        <Stack sx={{ alignItems: "center", gap: 1, px: 1, pb: 1 }}>
            <Stack
                direction="row"
                sx={{ gap: 0.5, flexWrap: "wrap", justifyContent: "center" }}
            >
                {socialLinks.map(({ icon: Icon, label, url }) => (
                    <IconButton
                        key={label}
                        color="secondary"
                        aria-label={label}
                        onClick={() => openExternal(url)}
                        sx={{ width: 36, height: 36, color: "text.muted" }}
                    >
                        <Icon fontSize="small" />
                    </IconButton>
                ))}
            </Stack>
            {build && (
                <Typography variant="mini" sx={{ color: "text.muted" }}>
                    {build}
                </Typography>
            )}
        </Stack>
    );
};
