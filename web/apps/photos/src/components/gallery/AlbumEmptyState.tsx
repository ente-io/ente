import { Box, Stack, Typography } from "@mui/material";
import { t } from "i18next";

export function AlbumEmptyState() {
    return (
        <Stack sx={{ alignItems: "center", gap: "30.31px", px: 3, py: 3 }}>
            <Box
                aria-hidden
                sx={{ position: "relative", width: 265.209, height: 215.196 }}
            >
                <Box
                    component="img"
                    src="/images/empty-album/background.svg"
                    alt=""
                    sx={{ position: "absolute", left: -5.385, top: 10.765 }}
                />
                <Box
                    component="img"
                    src="/images/empty-album/duck.svg"
                    alt=""
                    sx={{ position: "absolute", left: 21.54, top: 23.22 }}
                />
            </Box>
            <Typography
                sx={{
                    fontFamily: "'Outfit Variable', sans-serif",
                    fontWeight: 600,
                    fontSize: { xs: 28, sm: "36.372px" },
                    lineHeight: "1.333333",
                    color: "text.base",
                    textAlign: "center",
                }}
            >
                {t("nothing_to_see_here")}
            </Typography>
        </Stack>
    );
}
