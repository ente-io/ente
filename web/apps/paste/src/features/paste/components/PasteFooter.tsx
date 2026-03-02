import { Box, Stack, Typography } from "@mui/material";
import { EnteLogo } from "ente-base/components/EnteLogo";

const productLinkSx = (hoverColor: string) => ({
    color: "rgba(230, 236, 255, 0.82)",
    fontWeight: 700,
    fontSize: { xs: "0.74rem", sm: "0.8rem" },
    letterSpacing: "0.03em",
    textDecoration: "underline",
    textDecorationColor: "rgba(230, 236, 255, 0.5)",
    textUnderlineOffset: "3px",
    cursor: "pointer",
    whiteSpace: "nowrap",
    transition: "color 180ms ease, text-decoration-color 180ms ease",
    "&:hover": {
        color: hoverColor,
        textDecoration: "underline",
        textDecorationColor: hoverColor,
    },
});

export const PasteFooter = () => (
    <Stack
        alignItems="center"
        spacing={1.1}
    >
        <Box
            component="a"
            href="https://ente.io"
            target="_blank"
            rel="noopener"
            aria-label="Ente"
            sx={{
                lineHeight: 0,
                color: "rgba(236, 243, 255, 0.92)",
                transition: "color 180ms ease",
                "&:hover": {
                    color: "#08C225",
                },
            }}
        >
            <EnteLogo height={26} />
        </Box>

        <Stack
            direction="row"
            spacing={1}
            alignItems="center"
            justifyContent="center"
            flexWrap="nowrap"
        >
            <Typography
                component="a"
                href="https://ente.io"
                target="_blank"
                rel="noopener"
                sx={productLinkSx("#08C225")}
            >
                Photos
            </Typography>
            <Box
                component="span"
                sx={{
                    width: 5,
                    height: 5,
                    borderRadius: "50%",
                    bgcolor: "rgba(230, 236, 255, 0.52)",
                }}
            />
            <Typography
                component="a"
                href="https://ente.io/locker"
                target="_blank"
                rel="noopener"
                sx={productLinkSx("#076AE2")}
            >
                Documents
            </Typography>
            <Box
                component="span"
                sx={{
                    width: 5,
                    height: 5,
                    borderRadius: "50%",
                    bgcolor: "rgba(230, 236, 255, 0.52)",
                }}
            />
            <Typography
                component="a"
                href="https://ente.io/auth"
                target="_blank"
                rel="noopener"
                sx={productLinkSx("#A75CFF")}
            >
                Auth
            </Typography>
        </Stack>
    </Stack>
);
