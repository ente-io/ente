import { ManagePublicLinkSettings } from "@/components/Collections/CollectionShare";
import type { RemotePullOpts } from "@/components/gallery";
import { useResolvedPublicLinkURL } from "@/components/share/useResolvedPublicLinkURL";
import { Stack, Typography } from "@mui/material";
import { CenteredFill } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import type { Collection } from "ente-media/collection";
import { t } from "i18next";
import { useEffect, useState } from "react";

interface ManageLinkPaneProps {
    collection: Collection | undefined;
    loading: boolean;
    onRemotePull: (opts?: RemotePullOpts) => Promise<void>;
    onLinkRemoved: (collectionID: number) => void;
}

export const ManageLinkPane = ({
    collection,
    loading,
    ...rest
}: ManageLinkPaneProps) => {
    if (loading)
        return (
            <CenteredFill>
                <ActivityIndicator />
            </CenteredFill>
        );
    if (!collection) {
        return (
            <CenteredFill>
                <Stack sx={{ gap: 1, p: 3, textAlign: "center" }}>
                    <Typography variant="h3">
                        {t("links_empty_title")}
                    </Typography>
                    <Typography sx={{ color: "text.muted" }}>
                        {t("links_empty_description")}
                    </Typography>
                </Stack>
            </CenteredFill>
        );
    }
    return (
        <SelectedLinkSettings
            key={collection.id}
            collection={collection}
            {...rest}
        />
    );
};

const closeSettings = () => {
    /* The inline settings have no parent drawer to close. */
};

const SelectedLinkSettings = ({
    collection,
    onRemotePull,
    onLinkRemoved,
}: Omit<ManageLinkPaneProps, "collection" | "loading"> & {
    collection: Collection;
}) => {
    const [publicURL, setPublicURL] = useState(collection.publicURLs[0]);
    useEffect(() => {
        setPublicURL(collection.publicURLs[0]);
    }, [collection.publicURLs]);
    const resolvedURL = useResolvedPublicLinkURL(collection, publicURL, true);
    const expired =
        publicURL &&
        publicURL.validTill > 0 &&
        publicURL.validTill < Date.now() * 1000;

    return (
        <Stack
            component="section"
            aria-label={t("manage_link")}
            sx={{
                flex: 1,
                minWidth: 0,
                minHeight: 0,
                overflowY: "auto",
                px: { xs: "14px", md: "24px" },
                pb: { xs: "16px", md: "36px" },
            }}
        >
            <Stack sx={{ width: "100%", maxWidth: 640, minWidth: 0, gap: 3 }}>
                <Stack sx={{ gap: 0.5 }}>
                    <Typography
                        component="h1"
                        variant="h3"
                        sx={{ overflowWrap: "anywhere" }}
                    >
                        {collection.name}
                    </Typography>
                    <Typography
                        variant="small"
                        sx={{ color: expired ? "critical.main" : "text.muted" }}
                    >
                        {expired ? t("link_expired") : t("active")}
                    </Typography>
                </Stack>
                <Stack sx={{ minWidth: 0 }}>
                    <Typography
                        component="h2"
                        sx={{ fontWeight: "medium", px: "8px" }}
                    >
                        {t("manage_link")}
                    </Typography>
                    {publicURL && resolvedURL ? (
                        <ManagePublicLinkSettings
                            key={publicURL.url}
                            inline
                            {...{
                                collection,
                                publicURL,
                                setPublicURL,
                                resolvedURL,
                                onRemotePull,
                                onLinkRemoved,
                            }}
                            onClose={closeSettings}
                            onRootClose={closeSettings}
                        />
                    ) : (
                        <ActivityIndicator />
                    )}
                </Stack>
            </Stack>
        </Stack>
    );
};
