import { usePublicLinkURL } from "@/components/utils/use-public-link-url";
import { Copy01Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import DoneIcon from "@mui/icons-material/Done";
import {
    Box,
    IconButton,
    Stack,
    Tooltip,
    Typography,
    styled,
} from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { useClipboardCopy } from "ente-base/components/utils/hooks";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { ItemCard } from "ente-new/photos/components/Tiles";
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import { openURL } from "ente-new/photos/utils/web";
import { t } from "i18next";

interface PublicLinkDetailsProps {
    collection: Collection;
    coverFile?: EnteFile;
}

export const PublicLinkDetails = ({
    collection,
    coverFile,
}: PublicLinkDetailsProps) => {
    const { customDomain } = useSettingsSnapshot();
    // Links navigation only contains the user's own quick links.
    const { resolvedURL, isLoading, error } = usePublicLinkURL(
        collection,
        collection.publicURLs[0],
        customDomain,
    );

    return (
        <Box
            sx={{
                flex: 1,
                minHeight: 0,
                overflow: "auto",
                p: { xs: "24px", md: "36px" },
            }}
        >
            <Stack sx={{ width: "100%", maxWidth: 364, gap: "14px" }}>
                <Box role="img" aria-label={collection.name}>
                    <ItemCard
                        key={`${collection.id}-${coverFile?.id ?? "empty"}`}
                        TileComponent={Cover}
                        coverFile={coverFile}
                    />
                </Box>
                <Stack
                    direction="row"
                    sx={(theme) => ({
                        alignItems: "center",
                        gap: "8px",
                        height: 52,
                        px: "16px",
                        borderRadius: "16px",
                        bgcolor: "fill.faint",
                        ...theme.applyStyles("light", { bgcolor: "#F4F4F4" }),
                    })}
                >
                    <Typography
                        component="span"
                        title={resolvedURL}
                        aria-live="polite"
                        sx={{
                            flex: 1,
                            minWidth: 0,
                            fontSize: 14,
                            fontWeight: 500,
                            lineHeight: "20px",
                            letterSpacing: 0,
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                        }}
                    >
                        {resolvedURL?.replace(/^https?:\/\//, "") ??
                            (error
                                ? t("generic_error")
                                : isLoading
                                  ? t("loading")
                                  : null)}
                    </Typography>
                    <CopyLinkButton
                        key={resolvedURL ?? "pending"}
                        url={resolvedURL}
                    />
                </Stack>
                <Typography
                    sx={{
                        color: "text.muted",
                        fontSize: "11.5px",
                        fontWeight: 400,
                        lineHeight: 1.45,
                        letterSpacing: 0,
                    }}
                >
                    {t("public_link_description")}
                </Typography>
                <FocusVisibleButton
                    color="secondary"
                    fullWidth
                    disabled={!resolvedURL}
                    onClick={() => {
                        if (resolvedURL) openURL(resolvedURL);
                    }}
                    sx={(theme) => ({
                        height: 52,
                        px: "24px",
                        py: "14px",
                        borderRadius: "20px",
                        fontSize: 14,
                        fontWeight: 500,
                        lineHeight: "20px",
                        letterSpacing: 0,
                        ...theme.applyStyles("light", {
                            bgcolor: "#EAEAEA",
                            "&:hover": { bgcolor: "secondary.hover" },
                        }),
                    })}
                >
                    {t("open_album")}
                </FocusVisibleButton>
            </Stack>
        </Box>
    );
};

const CopyLinkButton = ({ url }: { url: string | undefined }) => {
    const [copied, copy] = useClipboardCopy(url ?? "");
    const label = t(copied ? "copied" : "copy_link");
    return (
        <Tooltip title={label}>
            <span>
                <IconButton
                    aria-label={label}
                    disabled={!url}
                    onClick={copy}
                    sx={{
                        width: 36,
                        height: 36,
                        p: 0,
                        mr: "-6px",
                        borderRadius: "8px",
                    }}
                >
                    {copied ? (
                        <DoneIcon sx={{ fontSize: 24, color: "accent.main" }} />
                    ) : (
                        <HugeiconsIcon
                            icon={Copy01Icon}
                            size={24}
                            strokeWidth={1.5}
                        />
                    )}
                </IconButton>
            </span>
        </Tooltip>
    );
};

const Cover = styled("div")({
    position: "relative",
    width: "100%",
    aspectRatio: "1",
    borderRadius: 24,
    overflow: "hidden",
    "& > img": { width: "100%", height: "100%", objectFit: "cover" },
});
