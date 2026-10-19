import { Stack, Typography } from "@mui/material";
import { t } from "i18next";

interface PublicLinkHeaderProps {
    name: string;
    fileCount: number;
}

export const PublicLinkHeader = ({
    name,
    fileCount,
}: PublicLinkHeaderProps) => (
    <Stack
        component="header"
        sx={{ minWidth: 0, minHeight: 54, gap: "2px", mb: "24px" }}
    >
        <Typography
            component="h1"
            noWrap
            title={name}
            sx={{
                fontFamily: '"Outfit Variable", Outfit, sans-serif',
                fontSize: 24,
                fontWeight: 600,
                lineHeight: "32px",
            }}
        >
            {name}
        </Typography>
        <Typography
            sx={{
                color: "text.muted",
                fontSize: 14,
                fontWeight: 500,
                lineHeight: "20px",
            }}
        >
            {t("photos_count", { count: fileCount })}
        </Typography>
    </Stack>
);
